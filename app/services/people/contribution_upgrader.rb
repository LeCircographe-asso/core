# frozen_string_literal: true

require "ostruct"

module People
  class ContributionUpgrader
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :old_contribution, :new_contribution, :payment, :credit_applied, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :from_contribution_id, :integer
    attribute :to_formula_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    validates :from_contribution_id, presence: true
    validates :to_formula_id, presence: true
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :recorded_by_id, presence: true
    validate :person_identifier_present

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      target_person = resolve_person
      recorded_by = resolve_user

      result = target_person.upgrade_contribution!(
        from_contribution_id: from_contribution_id,
        to_formula_id: to_formula_id,
        payment_method: payment_method.to_sym,
        recorded_by: recorded_by
      )

      instrument_upgrade(target_person, recorded_by, result)

      success(
        old_contribution: result[:old_contribution],
        new_contribution: result[:new_contribution],
        payment: result[:payment],
        credit_applied: result[:credit_applied] || 0,
        message: I18n.t("services.success.contribution_upgraded")
      )
    rescue ActiveRecord::RecordNotFound => e
      failure(I18n.t("services.errors.record_not_found", message: e.message))
    rescue StandardError => e
      Rails.logger.error("[People::ContributionUpgrader] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure(I18n.t("services.errors.unexpected_error", action: "contribution upgrade", message: e.message))
    end

    private

    def resolve_person
      return person if person.present?

      Person.find(person_id)
    end

    def resolve_user
      User.find(recorded_by_id)
    end

    def instrument_upgrade(person, recorded_by, result)
      ActiveSupport::Notifications.instrument(
        "contribution.upgraded",
        person_id: person.id,
        from_contribution_id: from_contribution_id,
        to_formula_id: to_formula_id,
        payment_method: payment_method,
        recorded_by_id: recorded_by.id,
        amount_cents: result[:payment]&.total_cents || 0,
        credit_applied: result[:credit_applied] || 0
      )
    end

    def person_identifier_present
      errors.add(:person_id, "must be provided") if person.blank? && person_id.blank?
    end

    def success(old_contribution:, new_contribution:, payment:, credit_applied:, message:)
      Result.new(success?: true, old_contribution: old_contribution, new_contribution: new_contribution, payment: payment, credit_applied: credit_applied, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, old_contribution: nil, new_contribution: nil, payment: nil, credit_applied: 0, errors: Array(errors || message), message: message)
    end
  end
end
