# frozen_string_literal: true

require "ostruct"

module People
  class MembershipCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :membership, :payment, :errors, :message, :already_existed,
                         :member_number_changed, :old_member_number, :new_member_number, keyword_init: true)

    attribute :person
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string
    attribute :donation_cents, :integer
    attribute :started_at, :date

    validates :person, presence: true
    validates :membership_type_id, presence: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }

    def call
      return failure(I18n.t("services.validation.invalid_data"), errors.full_messages) unless valid?

      if person.memberships.active.current.exists?
        ActiveSupport::Notifications.instrument(
          "membership.skipped",
          person_id: person.id, reason: "already_active", membership_type_id: membership_type_id
        )
        return Result.new(success?: true, membership: person.memberships.active.current.first, payment: nil, errors: [],
                           message: I18n.t("services.success.membership_already_active"), already_existed: true,
                           member_number_changed: false, old_member_number: person.member_number, new_member_number: person.member_number)
      end

      membership_type = MembershipType.find(membership_type_id)
      recorded_by = find_recorded_by

      membership_data = nil
      ActiveRecord::Base.transaction do
        People::OfferPolicy.validate!(
          recorded_by: recorded_by,
          person: person,
          offer_type: "membership",
          offer_reason: offer_reason
        ) if payment_method == "offered"

        start_date = started_at || Date.current
        membership = person.memberships.create!(
          membership_type: membership_type,
          started_at: start_date,
          ended_at: start_date + 1.year,
          status: :active
        )

        old_member_number = person.member_number
        new_member_number = assign_or_reissue_member_number!(membership_type, recorded_by)

        amount_cents = amount_for(membership_type.price_cents)
        payment = record_payment!(
          item_type: "Membership",
          item_id: membership.id,
          amount_cents: amount_cents,
          description: payment_description(membership_type.name),
          notes: "Paiement pour #{payment_description(membership_type.name)}"
        )

        membership_data = {
          membership: membership, payment: payment,
          old_member_number: old_member_number, new_member_number: new_member_number
        }
      end

      ActiveSupport::Notifications.instrument(
        "membership.created",
        person_id: person.id, membership_id: membership_data[:membership].id, payment_id: membership_data[:payment].id,
        membership_type_id: membership_type.id, payment_method: payment_method
      )

      Result.new(
        success?: true,
        membership: membership_data[:membership],
        payment: membership_data[:payment],
        errors: [],
        message: I18n.t("services.success.membership_created"),
        already_existed: false,
        member_number_changed: membership_data[:old_member_number] != membership_data[:new_member_number],
        old_member_number: membership_data[:old_member_number],
        new_member_number: membership_data[:new_member_number]
      )
    rescue ActiveRecord::RecordNotFound => e
      ActiveSupport::Notifications.instrument("membership.failed", error: e.message, reason: "record_not_found")
      failure(I18n.t("services.errors.record_not_found", message: e.message))
    rescue ActiveRecord::RecordInvalid => e
      ActiveSupport::Notifications.instrument("membership.failed", error: e.message, reason: "validation")
      failure(I18n.t("services.errors.validation_error", message: e.message))
    rescue StandardError => e
      db_path = ActiveRecord::Base.connection_db_config&.database
      Rails.logger.error("[People::MembershipCreator] db=#{db_path} #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      ActiveSupport::Notifications.instrument("membership.failed", error: e.message, reason: "exception")
      failure(I18n.t("services.errors.unexpected_error", action: "membership creation", message: e.message))
    end

    private

    def find_recorded_by
      return @recorded_by if defined?(@recorded_by)

      if recorded_by_id.present?
        @recorded_by = User.find(recorded_by_id)
      elsif Current.respond_to?(:user) && Current.user.present?
        @recorded_by = Current.user
      else
        raise "A recorded_by user is required to create a membership"
      end
    end

    # Première adhésion (pas encore de numéro) : on assigne, comme avant.
    # Reprise (numéro déjà présent — la garde en tête de #call garantit qu'on n'arrive
    # ici que si la personne n'avait aucune adhésion en cours) : on réémet un nouveau
    # numéro et on trace le changement, même logique que People::MembershipUpgrader.
    def assign_or_reissue_member_number!(membership_type, recorded_by)
      category = membership_type.circus? ? "CIRQUE" : "BASIQUE"

      if person.member_number.present?
        MemberManagementService.reissue_member_number!(person, membership_type: category, recorded_by: recorded_by)
      else
        MemberManagementService.assign_member_number(person, category) unless Rails.env.test?
        person.member_number
      end
    end

    def amount_for(base_price_cents)
      return custom_amount_cents || 0 if payment_method == "offered"

      base_price_cents
    end

    def payment_description(name)
      PaymentLine.normalize_membership_name(name)
    end

    def record_payment!(item_type:, item_id:, amount_cents:, description:, notes:)
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

      result = People::PaymentRecorder.new(
        person: person,
        recorded_by: find_recorded_by,
        payment_method: payment_method,
        status: "success",
        notes: notes,
        offer_reason: offer_reason,
        total_cents: lines.sum { |line| line[:amount_cents].to_i },
        payment_lines: lines
      ).call

      raise result.message unless result.success?

      result.payment
    end

    def normalized_donation_cents
      cents = donation_cents.to_i
      cents.positive? ? cents : nil
    end

    def failure(message, error_list = nil)
      Result.new(
        success?: false,
        membership: nil,
        payment: nil,
        errors: Array(error_list || message),
        message: message,
        already_existed: false,
        member_number_changed: false,
        old_member_number: nil,
        new_member_number: nil
      )
    end
  end
end
