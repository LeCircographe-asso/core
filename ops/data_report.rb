# frozen_string_literal: true

# Data report: row counts per table + integrity checks on the primary database, as JSON.
#
#   bin/rails runner ops/data_report.rb                        # print the report
#   DATA_REPORT_BEFORE=before.json bin/rails runner ops/data_report.rb
#                                                              # compare with an earlier report,
#                                                              # exit 1 if data was lost or broken
#
# Used by `bin/docker-local upgrade` (docs/development/docker_local.md), which copies this
# file into images that predate it: keep it plain SQL, independent of the app's models
# (only the pack10 check asks the model for its enum value, and is skipped if it cannot),
# and skip any check whose tables or columns do not exist in the database it runs on.
# Read-only: never writes to the database. Rules: docs/domain/data_integrity_rules.md.

require "json"

module DataReport
  # Fallback when the image's PaymentLine has no ALLOWED_ITEM_TYPES (see allowed_line_item_types).
  ALLOWED_LINE_ITEM_TYPES = %w[Membership MembershipType MembershipUpgrade ContributionFormula Contribution Donation].freeze
  INTERNAL_TABLES = %w[schema_migrations ar_internal_metadata].freeze

  # name => [sql returning one count, { table => [columns] } it needs]
  CHECKS = {
    "users_without_person" => [
      "SELECT COUNT(*) FROM users LEFT JOIN people ON people.id = users.person_id WHERE people.id IS NULL",
      { "users" => %w[person_id], "people" => [] }
    ],
    "people_with_several_users" => [
      "SELECT COUNT(*) FROM (SELECT person_id FROM users GROUP BY person_id HAVING COUNT(*) > 1)",
      { "users" => %w[person_id] }
    ],
    "memberships_without_person" => [
      "SELECT COUNT(*) FROM memberships LEFT JOIN people ON people.id = memberships.person_id WHERE people.id IS NULL",
      { "memberships" => %w[person_id], "people" => [] }
    ],
    "contributions_without_person" => [
      "SELECT COUNT(*) FROM contributions LEFT JOIN people ON people.id = contributions.person_id WHERE people.id IS NULL",
      { "contributions" => %w[person_id], "people" => [] }
    ],
    "payments_without_person" => [
      "SELECT COUNT(*) FROM payments LEFT JOIN people ON people.id = payments.person_id WHERE people.id IS NULL",
      { "payments" => %w[person_id], "people" => [] }
    ],
    "payments_without_lines" => [
      "SELECT COUNT(*) FROM payments LEFT JOIN payment_lines ON payment_lines.payment_id = payments.id " \
      "WHERE payment_lines.id IS NULL AND payments.total_cents > 0",
      { "payments" => %w[total_cents], "payment_lines" => %w[payment_id] }
    ],
    "payments_lines_sum_mismatch" => [
      "SELECT COUNT(*) FROM (SELECT payments.id FROM payments JOIN payment_lines ON payment_lines.payment_id = payments.id " \
      "GROUP BY payments.id, payments.total_cents HAVING SUM(payment_lines.amount_cents) != payments.total_cents)",
      { "payments" => %w[total_cents], "payment_lines" => %w[payment_id amount_cents] }
    ],
    "legacy_donation_lines" => [
      "SELECT COUNT(*) FROM payment_lines WHERE item_type = 'Payment'",
      { "payment_lines" => %w[item_type] }
    ],
    "attendances_without_person" => [
      "SELECT COUNT(*) FROM attendances LEFT JOIN people ON people.id = attendances.person_id WHERE people.id IS NULL",
      { "attendances" => %w[person_id], "people" => [] }
    ]
  }.freeze

  module_function

  def connection = ActiveRecord::Base.connection

  def columns_of(table)
    @columns ||= {}
    @columns[table] ||= connection.columns(table).map(&:name)
  end

  def available?(needs)
    tables = connection.tables
    needs.all? { |table, columns| tables.include?(table) && (columns - columns_of(table)).empty? }
  end

  def count(sql, *binds)
    connection.select_value(binds.empty? ? sql : ActiveRecord::Base.sanitize_sql_array([ sql, *binds ])).to_i
  end

  def tables
    (connection.tables - INTERNAL_TABLES).sort.to_h do |table|
      [ table, count("SELECT COUNT(*) FROM #{connection.quote_table_name(table)}") ]
    end
  end

  # Session invariants per formula duration, as in Admin::HealthReport: pack10 and day
  # passes count sessions (day: 1 then 0), trimester/annual are unlimited (nil).
  # name => [durations, SQL condition on contributions.sessions_remaining that is invalid]
  CONTRIBUTION_SESSION_CHECKS = {
    "pack10_without_sessions_remaining" => [ %w[pack10], "contributions.sessions_remaining IS NULL" ],
    "day_pass_invalid_sessions" => [ %w[day], "(contributions.sessions_remaining IS NULL OR contributions.sessions_remaining NOT IN (0, 1))" ],
    "unlimited_with_sessions_remaining" => [ %w[trimester annual], "contributions.sessions_remaining IS NOT NULL" ]
  }.freeze
  CONTRIBUTION_NEEDS = { "contributions" => %w[contribution_formula_id sessions_remaining], "contribution_formulas" => %w[duration] }.freeze

  def checks
    results = CHECKS.transform_values { |(sql, needs)| available?(needs) ? count(sql) : "skipped" }
    results["unknown_line_item_types"] = unknown_line_item_types
    CONTRIBUTION_SESSION_CHECKS.each { |name, (durations, condition)| results[name] = contribution_session_check(durations, condition) }
    results
  end

  # The image's own whitelist is the right one for the data it writes; fallback for images without it.
  def allowed_line_item_types
    defined?(PaymentLine::ALLOWED_ITEM_TYPES) ? PaymentLine::ALLOWED_ITEM_TYPES : ALLOWED_LINE_ITEM_TYPES
  end

  def unknown_line_item_types
    return "skipped" unless available?("payment_lines" => %w[item_type])

    count("SELECT COUNT(*) FROM payment_lines WHERE item_type NOT IN (?)", allowed_line_item_types)
  end

  # duration is an integer enum: ask the model for the values, skip if the model differs.
  def contribution_session_check(durations, condition)
    values = durations.map { |duration| ContributionFormula.durations.fetch(duration) }
    return "skipped" unless available?(CONTRIBUTION_NEEDS)

    count("SELECT COUNT(*) FROM contributions JOIN contribution_formulas " \
          "ON contribution_formulas.id = contributions.contribution_formula_id " \
          "WHERE contribution_formulas.duration IN (?) AND #{condition}", values.map { |value| Integer(value) })
  rescue NameError, NoMethodError, KeyError
    "skipped"
  end

  def report
    {
      "generated_at" => Time.now.utc.iso8601,
      "schema_version" => connection.select_value("SELECT MAX(version) FROM schema_migrations").to_s,
      "sqlite_integrity" => connection.select_values("PRAGMA integrity_check").join("; "),
      "foreign_key_violations" => connection.select_all("PRAGMA foreign_key_check").to_a.size,
      "tables" => tables,
      "checks" => checks
    }
  end

  # Problems going from `before` to `after`: rows lost, a table gone, an anomaly that grew,
  # SQLite corruption. New tables and new rows are fine (migrations may add them).
  def problems(before, after)
    issues = []
    issues << "sqlite integrity: #{after['sqlite_integrity']}" unless after["sqlite_integrity"] == "ok"
    if after["foreign_key_violations"] > before.fetch("foreign_key_violations", 0)
      issues << "foreign key violations: #{before['foreign_key_violations']} -> #{after['foreign_key_violations']}"
    end
    before.fetch("tables", {}).each do |table, rows|
      now = after["tables"][table]
      if now.nil?
        issues << "table #{table} disappeared (#{rows} rows)" if rows.positive?
      elsif now < rows
        issues << "table #{table} lost rows: #{rows} -> #{now}"
      end
    end
    after["checks"].each do |name, now|
      was = before.fetch("checks", {})[name]
      next unless now.is_a?(Integer) && now.positive?

      issues << "check #{name}: #{was.is_a?(Integer) ? was : 'n/a'} -> #{now}" if !was.is_a?(Integer) || now > was
    end
    issues
  end
end

# Only when run (`bin/rails runner` sets $0 to the file); spec/ops/data_report_spec.rb loads
# it for DataReport alone.
if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)
  report = DataReport.report
  before_path = ENV.fetch("DATA_REPORT_BEFORE", nil)
  issues = nil

  if before_path
    before = JSON.parse(File.read(before_path))
    issues = DataReport.problems(before, report)
    report = report.merge("compared_with" => before["schema_version"], "problems" => issues)
  end

  # DATA_REPORT_OUTPUT=<file>: write there instead of stdout, which the app's logger may share.
  if (output = ENV.fetch("DATA_REPORT_OUTPUT", nil))
    File.write(output, JSON.pretty_generate(report))
  else
    puts JSON.pretty_generate(report)
  end
  exit(issues.nil? || issues.empty? ? 0 : 1)
end
