# frozen_string_literal: true

require 'ostruct'

module People
  class ContributionCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :contribution, :payment, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :contribution_formula_id, :integer
    attribute :payment_method, :string, default: 'cash'
    attribute :recorded_by_id, :integer
    attribute :record_attendance, :boolean, default: false
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string
    attribute :donation_cents, :integer

    validates :contribution_formula_id, presence: true
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered pending] }
    validate :person_present
    validate :recorded_by_present

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      target_person = resolve_person
      contribution_formula = ContributionFormula.find(contribution_formula_id)
      recorded_by = resolve_recorded_by

      result = target_person.create_contribution!(
        contribution_formula,
        payment_method: payment_method.to_sym,
        recorded_by: recorded_by,
        record_attendance: record_attendance,
        custom_amount_cents: custom_amount_cents,
        offer_reason: offer_reason,
        donation_cents: donation_cents
      )

      instrument_contribution_created(target_person, contribution_formula, recorded_by, result[:contribution], result[:payment])

      success(
        contribution: result[:contribution],
        payment: result[:payment],
        message: 'Contribution created successfully'
      )
    rescue ActiveRecord::RecordNotFound => e
      ActiveSupport::Notifications.instrument('contribution.failed', error: e.message, reason: 'record_not_found')
      failure("Record not found: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::ContributionCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      ActiveSupport::Notifications.instrument('contribution.failed', error: e.message, reason: 'exception')
      failure("Error creating contribution: #{e.message}")
    end

    private

    def resolve_person
      return person if person.present?
      raise ActiveRecord::RecordNotFound, 'Person not found' if person_id.blank?

      Person.find(person_id)
    end

    def resolve_recorded_by
      return User.find(recorded_by_id) if recorded_by_id.present?

      raise ActiveRecord::RecordNotFound, 'Recorded_by user not provided' unless Current.respond_to?(:user) && Current.user.present?

      Current.user
    end

    def instrument_contribution_created(person, contribution_formula, recorded_by, contribution, payment)
      ActiveSupport::Notifications.instrument(
        'contribution.created',
        person_id: person.id,
        contribution_id: contribution.id,
        contribution_formula: contribution_formula.name,
        payment_method: payment_method,
        recorded_by_id: recorded_by.id,
        amount_cents: payment.total_cents
      )
    end

    def success(contribution:, payment:, message:)
      Result.new(success?: true, contribution: contribution, payment: payment, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, contribution: nil, payment: nil, errors: Array(errors || message), message: message)
    end

    def person_present
      return if person.present? || person_id.present?

      errors.add(:person, 'must be provided')
    end

    def recorded_by_present
      return if recorded_by_id.present? || (Current.respond_to?(:user) && Current.user.present?)

      errors.add(:recorded_by_id, 'must be provided')
    end
  end
end
