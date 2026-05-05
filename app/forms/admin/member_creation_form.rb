# frozen_string_literal: true

require "ostruct"

module Admin
  class MemberCreationForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Attributs pour la création de personne
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :address, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
    attribute :birth_date, :date
    attribute :emergency_contact_name, :string
    attribute :emergency_contact_phone, :string
    attribute :notes, :string
    attribute :specialty, :string
    attribute :is_minor, :boolean, default: false
    attribute :image_rights, :boolean, default: false
    attribute :get_involved, :boolean, default: false
    attribute :newsletter_subscribed, :boolean, default: false
    attribute :dyslexic_font, :boolean, default: false
    attribute :reduced_rate_eligible, :boolean, default: false
    attribute :reduced_rate_reason, :string
    attribute :reduced_rate_proof, :string

    # Attributs pour la création de compte utilisateur
    attribute :create_web_account, :boolean, default: false
    attribute :email_address, :string
    attribute :system_role, :string, default: "web_visitor"

    # Attributs pour l'adhésion
    attribute :create_membership, :boolean, default: false
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"

    # ID de personne existante (si on crée un compte pour une personne existante)
    attribute :person_id, :integer

    validates :first_name, presence: true, if: -> { person_id.blank? }
    validates :last_name, presence: true, if: -> { person_id.blank? }
    validates :email_address, presence: true, if: -> { create_web_account == true }
    validates :system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validates :membership_type_id, presence: true, if: :membership_requested?
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }

    def call
      return failure(I18n.t("admin.members.create.invalid_data_alert", details: errors.full_messages.join(", "))) unless valid?

      existing_person = person_id.present? ? Person.active.find_by(id: person_id) : nil
      return failure("Person not found") if person_id.present? && existing_person.nil?

      result = People::Register.new(
        person_params: person_attributes.except(:newsletter_subscribed).compact_blank,
        existing_person: existing_person,
        newsletter_subscribed: newsletter_subscribed,
        newsletter_source: "admin",
        create_user_account: create_web_account,
        user_params: user_creation_params(compact: true),
        create_membership: membership_requested?,
        membership_params: membership_creation_params
      ).call

      if result.success?
        success(result.person, translate_success_message(result))
      else
        failure(translate_error_message(result.message), result.errors)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def person_attributes
      {
        first_name: first_name,
        last_name: last_name,
        email: email,
        phone: phone,
        address: address,
        zip_code: zip_code,
        town: town,
        country: country,
        birth_date: birth_date,
        emergency_contact_name: emergency_contact_name,
        emergency_contact_phone: emergency_contact_phone,
        notes: notes,
        specialty: specialty,
        is_minor: is_minor,
        image_rights: image_rights,
        get_involved: get_involved,
        newsletter_subscribed: newsletter_subscribed,
        dyslexic_font: dyslexic_font,
        reduced_rate_eligible: reduced_rate_eligible,
        reduced_rate_reason: reduced_rate_reason,
        reduced_rate_proof: reduced_rate_proof
      }
    end

    def user_creation_params(compact: false)
      payload = {
        email_address: email_address,
        system_role: system_role,
        created_by_admin: true
      }
      compact ? payload.compact_blank : payload
    end

    def membership_creation_params
      return {} unless membership_requested?

      {
        membership_type_id: membership_type_id,
        payment_method: payment_method,
        recorded_by_id: Current.user&.id
      }.compact_blank
    end

    def membership_requested?
      create_membership || membership_type_id.present?
    end

    def success(person, message)
      OpenStruct.new(
        success?: true,
        person: person,
        message: message
      )
    end

    def failure(message, error_list = nil)
      OpenStruct.new(
        success?: false,
        errors: Array(error_list || message),
        message: message
      )
    end

    def translate_success_message(result)
      if result.user && result.membership
        I18n.t("admin.members.create.success_person_user_membership")
      elsif result.user
        I18n.t("admin.members.create.success_person_user")
      elsif result.membership
        I18n.t("admin.members.create.success_person_membership")
      else
        I18n.t("admin.members.create.success_person_only")
      end
    end

    def translate_error_message(message)
      return I18n.t("admin.members.create.error_existing_web_account") if message.include?("déjà un compte web") || message.include?("already has a user")
      return I18n.t("admin.members.create.error_email_required") if message.include?("email is required")

      message
    end
  end
end
