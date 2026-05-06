# frozen_string_literal: true

module Admin
  module Members
    module ParameterHandling
      extend ActiveSupport::Concern

      PERSON_FORM_KEYS = %i[
        first_name
        last_name
        email
        phone
        birth_date
        address
        emergency_contact_name
        emergency_contact_phone
        notes
        specialty
        is_minor
        image_rights
        get_involved
        newsletter_subscribed
        dyslexic_font
        zip_code
        town
        country
        reduced_rate_eligible
        reduced_rate_reason
        reduced_rate_proof
      ].freeze

      USER_CONTROL_KEYS = %i[
        email_address
        system_role
        created_by_admin
        create_web_account
      ].freeze

      PERSON_EDIT_KEYS = %i[
        first_name
        last_name
        email
        phone
        address
        zip_code
        town
        country
        birth_date
        emergency_contact_name
        emergency_contact_phone
        notes
        newsletter_subscribed
        get_involved
        image_rights
        is_minor
        reduced_rate_eligible
        reduced_rate_reason
        reduced_rate_proof
      ].freeze

      USER_EXPECTED_KEYS = [
        *USER_CONTROL_KEYS,
        *PERSON_FORM_KEYS,
        { person: %i[id] + PERSON_FORM_KEYS }
      ].freeze

      private

      def member_params
        params.expect(member: USER_EXPECTED_KEYS)
      end

      def member_creation_params
        person_attributes = nested_member_person_params

        person_attributes.slice(*PERSON_FORM_KEYS).merge(
          create_web_account: params.dig(:member, :create_web_account),
          email_address: params.dig(:member, :email_address) || person_attributes[:email],
          system_role: params.dig(:member, :system_role),
          create_membership: params.dig(:member, :create_membership),
          membership_type_id: params.dig(:member, :membership_type_id),
          payment_method: params.dig(:member, :payment_method),
          person_id: params.dig(:member, :person_id)
        ).compact
      end

      def person_params
        params.expect(person: PERSON_EDIT_KEYS)
      end

      def nested_member_person_params
        raw_person_params = params.dig(:member, :person)
        return {} unless raw_person_params.respond_to?(:permit)

        raw_person_params.permit(*PERSON_FORM_KEYS).to_h.symbolize_keys
      end
    end
  end
end
