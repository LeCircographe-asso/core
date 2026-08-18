# frozen_string_literal: true

require "ostruct"

module People
  class ContributionCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(
      :success?, :contribution, :contributions, :payment, :attendance, :attendances, :attendance_warnings, :errors, :message,
      keyword_init: true
    )

    attr_accessor :person, :beneficiaries

    attribute :person_id, :integer
    attribute :contribution_formula_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :record_attendance, :boolean, default: false
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string
    attribute :donation_cents, :integer
    attribute :purchased_at, :datetime

    validates :contribution_formula_id, presence: true, if: -> { beneficiaries.blank? }
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered pending] }
    validate :person_present
    validate :recorded_by_present

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      payer = resolve_person
      recorded_by = resolve_recorded_by
      entries = resolve_beneficiary_entries

      result = nil
      ActiveRecord::Base.transaction do
        created = entries.map { |entry| create_beneficiary_purchase(entry, recorded_by) }

        payment = record_payment!(
          payer: payer,
          recorded_by: recorded_by,
          lines: created.map { |c| c[:line] },
          notes: "Paiement pour #{created.map { |c| c[:description] }.join(', ')}"
        )

        result = {
          contributions: created.map { |c| c[:contribution] },
          payment: payment,
          attendances: created.filter_map { |c| c[:attendance] },
          attendance_warnings: created.filter_map { |c| c[:attendance_error] }
        }

        instrument_contribution_created(recorded_by, created)
      end

      success(
        contributions: result[:contributions],
        payment: result[:payment],
        attendances: result[:attendances],
        attendance_warnings: result[:attendance_warnings],
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

    # Sans `beneficiaries`, le payeur est aussi l'unique bénéficiaire (comportement historique).
    # Avec `beneficiaries`, chaque entrée peut avoir une personne et une formule différentes ;
    # le payeur (`person`/`person_id`) règle pour tout le monde en un seul paiement.
    def resolve_beneficiary_entries
      return Array(beneficiaries).map { |entry| normalize_entry(entry) } if beneficiaries.present?

      [ { person: resolve_person, contribution_formula: ContributionFormula.find(contribution_formula_id), record_attendance: record_attendance? } ]
    end

    def normalize_entry(entry)
      entry = entry.symbolize_keys if entry.respond_to?(:symbolize_keys)

      {
        person: entry[:person] || Person.find(entry[:person_id]),
        contribution_formula: entry[:contribution_formula] || ContributionFormula.find(entry[:contribution_formula_id]),
        record_attendance: ActiveModel::Type::Boolean.new.cast(entry[:record_attendance])
      }
    end

    def create_beneficiary_purchase(entry, recorded_by)
      beneficiary = entry[:person]
      contribution_formula = entry[:contribution_formula]

      People::OfferPolicy.validate!(
        recorded_by: recorded_by,
        person: beneficiary,
        offer_type: "contribution",
        offer_reason: offer_reason,
        contribution_formula: contribution_formula
      ) if payment_method == "offered"

      raise "Cette personne doit avoir une adhésion Cirque active pour acheter une cotisation" unless beneficiary.can_buy_contribution_formulas?

      # Garde-fou métier : une cotisation active et utilisable couvre déjà les entraînements
      # libres, quelle que soit sa durée (ex. un annuel actif rend un daily redondant). Un
      # nouvel achat dans cet état n'est jamais légitime — passer par le passage de formule
      # (upgrade) si l'intention est de changer de formule, pas par un nouvel achat.
      if beneficiary.contributions.active.usable.exists?
        raise "#{beneficiary.full_name} a déjà une cotisation active — utilisez le passage de formule (upgrade) plutôt qu'un nouvel achat."
      end

      contribution = beneficiary.contributions.create!(
        People::ContributionPayloadBuilder.call(contribution_formula)
          .merge(contribution_formula: contribution_formula, status: :active, purchased_at: purchased_at || Time.current)
      )

      amount_cents = amount_for(contribution_formula.price_cents)
      description = payment_description(contribution_formula.name)
      attendance, attendance_error = entry[:record_attendance] ? record_attendance_for(beneficiary, contribution) : [ nil, nil ]

      {
        contribution: contribution,
        attendance: attendance,
        attendance_error: attendance_error,
        description: description,
        line: {
          item_type: "Contribution",
          item_id: contribution.id,
          person_id: beneficiary.id,
          amount_cents: amount_cents,
          description: description
        }
      }
    end

    def amount_for(base_price_cents)
      return custom_amount_cents || 0 if payment_method == "offered"

      base_price_cents
    end

    def payment_description(name)
      payment_method == "offered" ? "Cotisation offerte #{name}" : "Cotisation #{name}"
    end

    def record_attendance?
      record_attendance
    end

    # Échec non bloquant : la cotisation reste achetée même si la présence ne peut pas être
    # enregistrée (ex. jour fermé, déjà présent aujourd'hui) — mais la raison remonte jusqu'à
    # l'admin (via attendance_warnings) au lieu de disparaître silencieusement.
    def record_attendance_for(beneficiary, contribution)
      result = AttendanceManagement::CheckInService.new(
        person_id: beneficiary.id,
        contribution_id: contribution.id
      ).call

      result.success? ? [ result.attendance, nil ] : [ nil, "#{beneficiary.full_name} : #{result.message}" ]
    end

    def record_payment!(payer:, recorded_by:, lines:, notes:)
      all_lines = lines.dup

      if normalized_donation_cents.present?
        all_lines << {
          item_type: "Donation",
          amount_cents: normalized_donation_cents,
          description: "Donation"
        }
      end

      payment_result = People::PaymentRecorder.new(
        person: payer,
        recorded_by: recorded_by,
        payment_method: payment_method,
        status: "success",
        notes: notes,
        offer_reason: offer_reason,
        total_cents: all_lines.sum { |line| line[:amount_cents].to_i },
        payment_lines: all_lines
      ).call

      raise payment_result.message unless payment_result.success?

      payment_result.payment
    end

    def normalized_donation_cents
      cents = donation_cents.to_i
      cents.positive? ? cents : nil
    end

    def instrument_contribution_created(recorded_by, created)
      created.each do |c|
        ActiveSupport::Notifications.instrument(
          "contribution.created",
          person_id: c[:contribution].person_id,
          contribution_id: c[:contribution].id,
          contribution_formula: c[:contribution].contribution_formula.name,
          payment_method: payment_method,
          recorded_by_id: recorded_by.id,
          amount_cents: c[:line][:amount_cents]
        )
      end
    end

    def success(contributions:, payment:, attendances:, message:, attendance_warnings: [])
      Result.new(
        success?: true,
        contribution: contributions.first,
        contributions: contributions,
        payment: payment,
        attendance: attendances.first,
        attendances: attendances,
        attendance_warnings: attendance_warnings,
        errors: [],
        message: message
      )
    end

    def failure(message, errors = nil)
      Result.new(
        success?: false,
        contribution: nil,
        contributions: [],
        payment: nil,
        attendance: nil,
        attendances: [],
        attendance_warnings: [],
        errors: Array(errors || message),
        message: message
      )
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
