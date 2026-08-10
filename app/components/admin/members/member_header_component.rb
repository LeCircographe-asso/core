# frozen_string_literal: true

module Admin
  module Members
    class MemberHeaderComponent < ViewComponent::Base
      def initialize(user:, person:, is_person_without_user: false, is_deleted: false, current_user: nil)
        @user = user
        @person = person
        @is_person_without_user = is_person_without_user
        @is_deleted = is_deleted
        @current_user = current_user
      end

      private

      attr_reader :user, :person, :is_person_without_user, :is_deleted, :current_user

      def user_name
        person.full_name.presence || "Adhérent ##{person.id}"
      end

      def user_email
        user&.email_address || person.email
      end

      # Source unique : Roleable#avatar_filename / #avatar_alt (User).
      def avatar_image
        user&.avatar_filename || Roleable::DEFAULT_AVATAR.first
      end

      def avatar_alt
        user&.avatar_alt || Roleable::DEFAULT_AVATAR.last
      end

      def crown?
        user&.super_admin? || false
      end
    end
  end
end
