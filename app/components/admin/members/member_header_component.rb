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

      def role_text
        return "Sans compte web" if user.nil?

        case user.system_role
        when "volunteer" then "Bénévole"
        when "super_admin" then "Super Admin"
        when "admin" then "Admin"
        when "web_visitor" then "Visiteur Web"
        else user.system_role.humanize
        end
      end

      def avatar_image
        case user&.system_role
        when "super_admin" then "super_admin.webp"
        when "admin" then "admin.webp"
        when "volunteer" then "volunteer.webp"
        else "users.png"
        end
      end

      def avatar_alt
        case user&.system_role
        when "super_admin" then "Avatar Super Admin"
        when "admin" then "Avatar Admin"
        when "volunteer" then "Avatar Bénévole"
        when "web_visitor" then "Avatar Utilisateur"
        else "Avatar"
        end
      end

      def crown?
        user&.system_role == "super_admin"
      end
    end
  end
end
