# frozen_string_literal: true

# Render a data report (ops/data_report.rb JSON) for a GitHub Actions run, without Rails:
#
#   ruby ops/data_report_summary.rb <report.json> <environment>
#
# Markdown goes to $GITHUB_STEP_SUMMARY (stdout when unset); each anomaly becomes a
# ::warning:: annotation on stdout. Never fails the job: the deploy is already done, the
# report tells whether the real data needs a look (docs/operations/deployment.md).

require "json"

path, environment = ARGV
report = JSON.parse(File.read(path))
checks = report.fetch("checks")
tables = report.fetch("tables")
anomalies = checks.select { |_name, value| value.is_a?(Integer) && value.positive? }
sqlite_ok = report["sqlite_integrity"] == "ok"
fk_violations = report.fetch("foreign_key_violations", 0)
healthy = anomalies.empty? && sqlite_ok && fk_violations.zero?

key_tables = %w[people users memberships contributions payments payment_lines attendances]
lines = []
lines << "## Data report: #{environment} #{healthy ? '✅' : '⚠️'}"
lines << ""
lines << "Schema `#{report['schema_version']}`, generated #{report['generated_at']}. " \
         "SQLite integrity: `#{report['sqlite_integrity']}`, foreign key violations: #{fk_violations}."
lines << ""
lines << "| Table | Rows |"
lines << "| --- | ---: |"
key_tables.each { |table| lines << "| #{table} | #{tables.fetch(table, 'n/a')} |" if tables.key?(table) }
lines << "| *all #{tables.size} tables* | #{tables.values.sum} |"
lines << ""
lines << "| Check | Result |"
lines << "| --- | ---: |"
checks.each { |name, value| lines << "| #{name} | #{value.is_a?(Integer) && value.positive? ? "**#{value}** ⚠️" : value} |" }
lines << ""

markdown = lines.join("\n")
if (summary = ENV.fetch("GITHUB_STEP_SUMMARY", nil))
  File.write(summary, "#{markdown}\n", mode: "a")
else
  puts markdown
end

anomalies.each { |name, value| puts "::warning title=Data report (#{environment})::#{name}: #{value}" }
puts "::warning title=Data report (#{environment})::SQLite integrity: #{report['sqlite_integrity']}" unless sqlite_ok
puts "::warning title=Data report (#{environment})::foreign key violations: #{fk_violations}" unless fk_violations.zero?
