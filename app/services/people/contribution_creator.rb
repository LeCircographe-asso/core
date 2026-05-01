# frozen_string_literal: true

require "ostruct"

module People
  class ContributionCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :contribution, :payment, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :contribution_formula_id, :integer
    attribute :payment_method, :string, default: "cash"
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
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      target_person = resolve_person
      contribution_formula = ContributionFormula.find(contribution_formula_id)
      recorded_by = resolve_recorded_by

      result = nil
      ActiveRecord::Base.transaction do
        People::OfferPolicy.validate!(
          recorded_by: recorded_by,
          person: target_person,
          offer_type: "contribution",
          offer_reason: offer_reason,
          contribution_formula: contribution_formula
        ) if payment_method == "offered"

        raise "Cette personne doit avoir une adhésion Cirque active pour acheter une cotisation" unless target_person.can_buy_contribution_formulas?

        contribution = target_person.contributions.create!(
          People::ContributionPayloadBuilder.call(contribution_formula)
            .merge(contribution_formula: contribution_formula, status: :active, purchased_at: Time.current)
        )

        amount_cents = amount_for(contribution_formula.price_cents)
        description = payment_description(contribution_formula.name)
        payment = record_payment!(
          person: target_person,
          recorded_by: recorded_by,
          item_type: "Contribution",
          item_id: contribution.id,
          amount_cents: amount_cents,
          description: description,
          notes: "Paiement pour #{description}"
        )

        result = { contribution: contribution, payment: payment }
      end

      instrument_contribution_created(target_person, contribution_formula, recorded_by, result[:contribution], result[:payment])

      success(
        contribution: result[:contribution],
        payment: result[:payment],
        message: I18n.t("services.success.contribution_created")
      )
    rescue ActiveRecord::RecordNotFound => e
      ActiveSupport::Notifications.instrument("contribution.failed", error: e.message, reason: "record_not_found")
      failure(I18n.t("services.errors.record_not_found", message: e.message))
    rescue StandardError => e
      Rails.logger.error("[People::ContributionCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      ActiveSupport::Notifications.instrument("contribution.failed", error: e.message, reason: "exception")
      failure(I18n.t("services.errors.unexpected_error", action: "contribution creation", message: e.message))
    end

    private

    def resolve_person
      return person if person.present?
      raise ActiveRecord::RecordNotFound, "Person not found" if person_id.blank?

      Person.find(person_id)
    end

    def resolve_recorded_by
      return User.find(recorded_by_id) if recorded_by_id.present?

      raise ActiveRecord::RecordNotFound, "Recorded_by user not provided" unless Current.respond_to?(:user) && Current.user.present?

      Current.user
    end

    def amount_for(base_price_cents)
      return custom_amount_cents || 0 if payment_method == "offered"

      base_price_cents
    end

    def payment_description(name)
      payment_method == "offered" ? "Cotisation offerte #{name}" : "Cotisation #{name}"
    end

    def record_payment!(person:, recorded_by:, item_type:, item_id:, amount_cents:, description:, notes:)
      lines = [
        {
          item_type: item_type,
          item_id: item_id,
          amount_cents: amount_cents,
          description: description
        }
      ]

      if normalized_donation_cents.present?
        lines << {
          item_type: "Donation",
          amount_cents: normalized_donation_cents,
          description: "Donation"
        }
      end

      payment_result = People::PaymentRecorder.new(
        person: person,
        recorded_by: recorded_by,
        payment_method: payment_method,
        status: "success",
        notes: notes,
        total_cents: lines.sum { |line| line[:amount_cents].to_i },
        payment_lines: lines
      ).call

      raise payment_result.message unless payment_result.success?

      payment_result.payment
    end

    def normalized_donation_cents
      cents = donation_cents.to_i
      cents.positive? ? cents : nil
    end

    def instrument_contribution_created(person, contribution_formula, recorded_by, contribution, payment)
      ActiveSupport::Notifications.instrument(
        "contribution.created",
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

      errors.add(:person, "must be provided")
    end

    def recorded_by_present
      return if recorded_by_id.present? || (Current.respond_to?(:user) && Current.user.present?)

      errors.add(:recorded_by_id, "must be provided")
    end
  end
end
