# frozen_string_literal: true

module Admin
  class HealthReport
    MAX_LIST = 50
    DUPLICATE_FIELDS = %i[email phone].freeze
    ContributionIssue = Struct.new(:contribution, :message, keyword_init: true)

    Result = Struct.new(
      :users_without_person,
      :users_without_person_count,
      :people_without_user,
      :people_without_user_count,
      :duplicate_people_by_email,
      :duplicate_people_by_email_count,
      :duplicate_people_by_phone,
      :duplicate_people_by_phone_count,
      :payments_without_person,
      :payments_without_person_count,
      :payments_without_lines,
      :payments_without_lines_count,
      :payments_with_mismatched_totals,
      :payments_with_mismatched_totals_count,
      :legacy_donation_lines,
      :legacy_donation_lines_count,
      :contribution_invariant_issues,
      :contribution_invariant_issues_count,
      keyword_init: true
    )

    def call
      users_without_person = User.left_joins(:person).where(people: { id: nil }).order(:created_at)
      people_without_user = PersonQuery.active.where.missing(:user).order(:created_at)
      payments_without_person = Payment.where(person_id: nil).order(:created_at)
      payments_without_lines = Payment.includes(:person, :recorded_by).where.missing(:payment_lines).order(:created_at)
      payments_with_mismatched_totals = payment_total_mismatches
      legacy_donation_lines = PaymentLine.where(item_type: "Payment").includes(payment: :person).order(:created_at)
      contribution_invariant_issues = build_contribution_invariant_issues

      email_keys = duplicate_keys(PersonQuery.active, :email, normalize: true)
      phone_keys = duplicate_keys(PersonQuery.active, :phone, normalize: false)

      Result.new(
        users_without_person: users_without_person.limit(MAX_LIST),
        users_without_person_count: users_without_person.count,
        people_without_user: people_without_user.limit(MAX_LIST),
        people_without_user_count: people_without_user.count,
        duplicate_people_by_email: people_by_keys(PersonQuery.active, :email, email_keys, normalize: true).limit(MAX_LIST),
        duplicate_people_by_email_count: email_keys.size,
        duplicate_people_by_phone: people_by_keys(PersonQuery.active, :phone, phone_keys, normalize: false).limit(MAX_LIST),
        duplicate_people_by_phone_count: phone_keys.size,
        payments_without_person: payments_without_person.limit(MAX_LIST),
        payments_without_person_count: payments_without_person.count,
        payments_without_lines: payments_without_lines.limit(MAX_LIST),
        payments_without_lines_count: payments_without_lines.count,
        payments_with_mismatched_totals: payments_with_mismatched_totals.limit(MAX_LIST),
        payments_with_mismatched_totals_count: grouped_count(payments_with_mismatched_totals),
        legacy_donation_lines: legacy_donation_lines.limit(MAX_LIST),
        legacy_donation_lines_count: legacy_donation_lines.count,
        contribution_invariant_issues: contribution_invariant_issues.first(MAX_LIST),
        contribution_invariant_issues_count: contribution_invariant_issues.size
      )
    end

    private

    def payment_total_mismatches
      Payment.includes(:person, :recorded_by)
             .left_joins(:payment_lines)
             .group("payments.id")
             .having("COUNT(payment_lines.id) > 0")
             .having("COALESCE(SUM(payment_lines.amount_cents), 0) != payments.total_cents")
             .select("payments.*, COALESCE(SUM(payment_lines.amount_cents), 0) AS lines_total_cents, COUNT(payment_lines.id) AS payment_lines_count")
             .order(:created_at)
    end

    def grouped_count(relation)
      relation.except(:select, :order).count.size
    end

    def build_contribution_invariant_issues
      contributions = Contribution.includes(:person, :contribution_formula)
                                  .joins(:contribution_formula)
                                  .where(contribution_formulas: { duration: %w[day trimester annual] })
                                  .order(:created_at)

      contributions.flat_map do |contribution|
        contribution_issues_for(contribution)
      end
    end

    def contribution_issues_for(contribution)
      duration = contribution.contribution_formula.duration

      case duration
      when "day"
        day_contribution_issues(contribution)
      when "trimester", "annual"
        unlimited_contribution_issues(contribution)
      else
        []
      end
    end

    def day_contribution_issues(contribution)
      issues = []

      unless contribution.sessions_remaining.in?([ 0, 1 ])
        issues << ContributionIssue.new(
          contribution: contribution,
          message: "Cotisation journee avec sessions_remaining invalide (attendu: 1 puis 0)"
        )
      end

      if contribution.purchased_at.present? && contribution.expires_at.present? &&
         contribution.expires_at.to_i != contribution.purchased_at.end_of_day.to_i
        issues << ContributionIssue.new(
          contribution: contribution,
          message: "Cotisation journee avec expiration differente de la fin du jour d'achat"
        )
      end

      issues
    end

    def unlimited_contribution_issues(contribution)
      return [] if contribution.sessions_remaining.nil?

      [
        ContributionIssue.new(
          contribution: contribution,
          message: "Cotisation #{contribution.contribution_formula.duration} avec sessions_remaining non nil"
        )
      ]
    end

    def duplicate_keys(scope, field, normalize: true)
      raise ArgumentError, "unsupported field" unless DUPLICATE_FIELDS.include?(field)

      t = scope.klass.arel_table
      col = t[field]
      expr = normalize ? Arel::Nodes::NamedFunction.new("LOWER", [ col ]) : col

      scope.where.not(field => [ nil, "" ])
           .group(expr)
           .having("COUNT(*) > 1")
           .pluck(expr)
    end

    def people_by_keys(scope, field, keys, normalize: true)
      return scope.none if keys.empty?

      raise ArgumentError, "unsupported field" unless DUPLICATE_FIELDS.include?(field)

      t = scope.klass.arel_table
      col = t[field]

      if normalize
        lowered = Arel::Nodes::NamedFunction.new("LOWER", [ col ])
        scope.where(lowered.in(keys))
             .order(lowered, t[:last_name], t[:first_name])
      else
        scope.where(field => keys)
             .order(t[field], t[:last_name], t[:first_name])
      end
    end
  end
end
