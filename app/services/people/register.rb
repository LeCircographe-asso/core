require "ostruct"

module People
  class Register
    Result = Struct.new(:success?, :person, :user, :membership, :errors, :message, keyword_init: true)

    attr_reader :person_params, :existing_person, :newsletter_subscribed, :newsletter_source,
                :create_user_account, :user_params, :create_membership, :membership_params

    def initialize(person_params:, existing_person: nil, newsletter_subscribed: nil, newsletter_source: "admin",
                   create_user_account: false, user_params: {}, create_membership: false, membership_params: {})
      @person_params = person_params || {}
      @existing_person = existing_person
      @newsletter_subscribed = newsletter_subscribed
      @newsletter_source = newsletter_source
      @create_user_account = create_user_account
      @user_params = user_params || {}
      @create_membership = create_membership
      @membership_params = membership_params || {}
    end

    def call
      payload = {
        person_id: existing_person&.id,
        person_email: person_params[:email],
        create_user_account: create_user_account,
        create_membership: should_create_membership?
      }

      ActiveRecord::Base.transaction do
        person_result = People::PersonCreator.new(person_creator_params).call
        return failure_from(person_result) unless person_result.success?

        person = person_result.person

        if create_user_account && person.user.present?
          return failure("Cette personne a déjà un compte web.")
        end

        user = nil
        if create_user_account
          user_result = People::UserAccountCreator.new(user_creator_params(person)).call
          return failure_from(user_result) unless user_result.success?
          user = user_result.user
        end

        membership = nil
        if should_create_membership?
          membership_result = People::MembershipCreator.new(membership_creator_params(person)).call
          return failure_from(membership_result) unless membership_result.success?
          membership = membership_result.membership
        end

        payload[:person_id] = person.id
        payload[:user_id] = user&.id
        payload[:membership_id] = membership&.id
        payload[:result] = :success

        Rails.logger.info("[People::Register] success person_id=#{person.id} user_id=#{user&.id} membership_id=#{membership&.id}")
        ActiveSupport::Notifications.instrument("people.register", payload) do
          Result.new(
            success?: true,
            person: person,
            user: user,
            membership: membership,
            errors: [],
            message: build_success_message(person_result.created, user.present?, membership.present?)
          )
        end
      end
    rescue => e
      Rails.logger.error("[People::Register] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Registration failed: #{e.message}")
    end

    private

    def person_creator_params
      person_params.merge(
        person: existing_person,
        newsletter_subscribed: newsletter_subscribed,
        newsletter_source: newsletter_source
      )
    end

    def user_creator_params(person)
      user_params.merge(person: person)
    end

    def membership_creator_params(person)
      membership_params.merge(person: person)
    end

    def should_create_membership?
      create_membership && membership_params[:membership_type_id].present?
    end

    def failure_from(service_result)
      failure(service_result.message, service_result.errors)
    end

    def build_success_message(person_created, user_created, membership_created)
      parts = []
      parts << (person_created ? "Person created" : "Person updated")
      parts << "user account" if user_created
      parts << "membership" if membership_created
      "Successfully processed #{parts.join(" and ")}".strip
    end

    def failure(message, errors = [])
      Rails.logger.warn("[People::Register] failure message=#{message}")
      ActiveSupport::Notifications.instrument("people.register", {
        result: :failure,
        message: message,
        errors: Array(errors)
      })

      Result.new(
        success?: false,
        person: nil,
        user: nil,
        membership: nil,
        errors: Array(errors.presence || message),
        message: message
      )
    end
  end
end
