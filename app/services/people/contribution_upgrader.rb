# frozen_string_literal: true

require "ostruct"

module People
  class ContributionUpgrader
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :old_contribution, :new_contribution, :payment, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :from_contribution_id, :integer
    attribute :to_formula_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :offer_reason, :string

    validates :from_contribution_id, presence: true
    validates :to_formula_id, presence: true
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :recorded_by_id, presence: true
    validate :person_identifier_present

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      target_person = resolve_person
      recorded_by = resolve_user

      result = nil
      ActiveRecord::Base.transaction do
        raise "Adhésion Cirque active requise" unless target_person.can_buy_contribution_formulas?

        from_contribution = target_person.contributions.find(from_contribution_id)
        to_formula = ContributionFormula.find(to_formula_id)

        validate_contribution_upgrade!(from_contribution, to_formula)

        People::OfferPolicy.validate!(
          recorded_by: recorded_by,
          person: target_person,
          offer_type: "contribution_upgrade",
          offer_reason: offer_reason,
          contribution_formula: to_formula
        ) if payment_method == "offered"

        from_contribution.suspend!(reason: "Upgrade vers #{to_formula.name}")

        # Chaque formule a son propre prix, sans prorata ni crédit sur le temps
        # restant de l'ancienne cotisation — décision actée le 2026-08-19.
        new_contribution = target_person.contributions.create!(
          People::ContributionPayloadBuilder.call(to_formula)
            .merge(contribution_formula: to_formula, status: :active, purchased_at: Time.current)
        )

        payment = record_payment!(
          person: target_person,
          recorded_by: recorded_by,
          contribution: new_contribution,
          amount_cents: to_formula.price_cents,
          notes: "Upgrade cotisation: #{from_contribution.contribution_formula.name} → #{to_formula.name}"
        )

        result = {
          old_contribution: from_contribution,
          new_contribution: new_contribution,
          payment: payment
        }
      end

      instrument_upgrade(target_person, recorded_by, result)

      success(
        old_contribution: result[:old_contribution],
        new_contribution: result[:new_contribution],
        payment: result[:payment],
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
        amount_cents: result[:payment]&.total_cents || 0
      )
    end

    def record_payment!(person:, recorded_by:, contribution:, amount_cents:, notes:)
      payment_result = People::PaymentRecorder.new(
        person: person,
        recorded_by: recorded_by,
        payment_method: payment_method,
        status: "success",
        notes: notes,
        offer_reason: offer_reason,
        total_cents: amount_cents,
        payment_lines: [
          {
            item_type: "Contribution",
            item_id: contribution.id,
            amount_cents: amount_cents,
            description: "Upgrade cotisation"
          }
        ]
      ).call

      raise payment_result.message unless payment_result.success?

      payment_result.payment
    end

    def validate_contribution_upgrade!(from_contribution, to_formula)
      valid_upgrades = {
        "pack10" => %w[trimester annual],
        "trimester" => [ "annual" ]
      }

      from_duration = from_contribution.contribution_formula.duration
      to_duration = to_formula.duration
      allowed = valid_upgrades[from_duration]
      raise "Upgrade #{from_duration} → #{to_duration} non autorisé" unless allowed&.include?(to_duration)
    end

    def person_identifier_present
      errors.add(:person_id, "must be provided") if person.blank? && person_id.blank?
    end

    def success(old_contribution:, new_contribution:, payment:, message:)
      Result.new(success?: true, old_contribution: old_contribution, new_contribution: new_contribution, payment: payment, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, old_contribution: nil, new_contribution: nil, payment: nil, errors: Array(errors || message), message: message)
    end
  end
end
