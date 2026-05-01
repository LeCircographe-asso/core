# frozen_string_literal: true

require "ostruct"

module People
  class MembershipUpgrader
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :membership, :payment, :member_number_changed, :old_member_number, :new_member_number, :errors, :message, keyword_init: true)

    attribute :person
    attribute :new_membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string
    attribute :donation_cents, :integer

    validates :person, presence: true
    validates :new_membership_type_id, presence: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }

    def call
      return failure(I18n.t("services.validation.invalid_data"), errors.full_messages) unless valid?

      new_membership_type = MembershipType.find(new_membership_type_id)
      recorded_by = resolve_recorded_by

      result = nil
      ActiveRecord::Base.transaction do
        current_membership = person.current_membership
        raise "Aucune adhésion active à upgrader" unless current_membership

        People::OfferPolicy.validate!(
          recorded_by: recorded_by,
          person: person,
          offer_type: "membership_upgrade",
          offer_reason: offer_reason
        ) if payment_method == "offered"

        old_membership_type = current_membership.membership_type
        new_membership = current_membership.upgrade_to!(new_membership_type)
        old_member_number = person.member_number
        new_member_number = handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)
        amount_cents = amount_for(new_membership_type.price_cents)

        payment = record_payment!(
          item_type: "Membership",
          item_id: new_membership.id,
          amount_cents: amount_cents,
          description: "Upgrade d'adhésion de #{old_membership_type.name} vers #{new_membership_type.name} (plein tarif)"
        )

        result = {
          membership: new_membership,
          payment: payment,
          member_number_changed: old_member_number != new_member_number,
          old_member_number: old_member_number,
          new_member_number: new_member_number
        }
      end

      ActiveSupport::Notifications.instrument(
        "membership.upgraded",
        person_id: person.id, old_member_number: result[:old_member_number], new_member_number: result[:new_member_number],
        membership_id: result[:membership].id, payment_id: result[:payment].id, new_membership_type_id: new_membership_type.id,
        payment_method: payment_method
      )

      Result.new(
        success?: true,
        membership: result[:membership],
        payment: result[:payment],
        member_number_changed: result[:member_number_changed],
        old_member_number: result[:old_member_number],
        new_member_number: result[:new_member_number],
        errors: [],
        message: I18n.t("services.success.membership_upgraded")
      )
    rescue ActiveRecord::RecordNotFound => e
      ActiveSupport::Notifications.instrument("membership.upgrade_failed", error: e.message, reason: "record_not_found")
      failure(I18n.t("services.errors.record_not_found", message: e.message))
    rescue StandardError => e
      Rails.logger.error("[People::MembershipUpgrader] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      ActiveSupport::Notifications.instrument("membership.upgrade_failed", error: e.message, reason: "exception")
      failure(I18n.t("services.errors.unexpected_error", action: "membership upgrade", message: e.message))
    end

    private

    def resolve_recorded_by
      return @recorded_by if defined?(@recorded_by)

      if recorded_by_id.present?
        @recorded_by = User.find(recorded_by_id)
      elsif Current.respond_to?(:user) && Current.user.present?
        @recorded_by = Current.user
      else
        raise "A recorded_by user is required to upgrade a membership"
      end
    end

    def amount_for(base_price_cents)
      return custom_amount_cents || 0 if payment_method == "offered"

      base_price_cents
    end

    def record_payment!(item_type:, item_id:, amount_cents:, description:)
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
        recorded_by: resolve_recorded_by,
        payment_method: payment_method,
        status: "success",
        notes: description,
        offer_reason: offer_reason,
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

    def handle_member_number_change!(old_membership_type, new_membership_type, recorded_by)
      old_type_code = membership_type_code(old_membership_type)
      new_type_code = membership_type_code(new_membership_type)
      return person.member_number if old_type_code == new_type_code

      new_member_number = MemberManagementService.generate_member_number(new_type_code)
      create_member_number_change_history!(
        old_member_number: person.member_number,
        new_member_number: new_member_number,
        old_type: old_type_code,
        new_type: new_type_code,
        recorded_by: recorded_by
      )
      person.update!(member_number: new_member_number)
      new_member_number
    end

    def membership_type_code(membership_type)
      membership_type.circus? ? "CIRQUE" : "BASIQUE"
    end

    def create_member_number_change_history!(old_member_number:, new_member_number:, old_type:, new_type:, recorded_by:)
      if old_member_number.present?
        old_history = person.member_number_histories.where(member_number: old_member_number, replaced_at: nil).first
        old_history&.mark_as_replaced!
      end

      old_type_name = old_type == "CIRQUE" ? "Cirque" : "Basique"
      new_type_name = new_type == "CIRQUE" ? "Cirque" : "Basique"

      person.member_number_histories.create!(
        member_number: new_member_number,
        membership_type: new_type_name,
        year: Date.current.year,
        notes: "Changement automatique lors de l'upgrade d'adhésion (#{old_type_name} → #{new_type_name}) - Enregistré par #{recorded_by.email}",
        assigned_at: Time.current
      )
    end

    def failure(message, error_list = nil)
      Result.new(
        success?: false,
        membership: nil,
        payment: nil,
        member_number_changed: false,
        old_member_number: nil,
        new_member_number: nil,
        errors: Array(error_list || message),
        message: message
      )
    end
  end
end
