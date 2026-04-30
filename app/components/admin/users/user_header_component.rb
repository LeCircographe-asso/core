# frozen_string_literal: true

module Admin
  module Users
    class UserHeaderComponent < ViewComponent::Base
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
        user.full_name.presence || "Utilisateur ##{user.id}"
      end

      def user_email
        user.email_address
      end

      def role_text
        if is_person_without_user
          "Créer un espace utilisateur"
        elsif user.system_role.present?
          case user.system_role
          when "volunteer" then "Bénévole"
          when "super_admin" then "Super Admin"
          when "admin" then "Admin"
          when "web_visitor" then "Visiteur Web"
          else user.system_role.humanize
          end
        else
          "Créer un espace utilisateur"
        end
      end

      def avatar_image
        case user.system_role
        when "super_admin" then "super_admin.webp"
        when "admin" then "admin.webp"
        when "volunteer" then "volunteer.webp"
        when "web_visitor" then "users.png"
        else "users.png"
        end
      end

      def avatar_alt
        case user.system_role
        when "super_admin" then "Avatar Super Admin"
        when "admin" then "Avatar Admin"
        when "volunteer" then "Avatar Bénévole"
        when "web_visitor" then "Avatar Utilisateur"
        else "Avatar"
        end
      end

      # Show crown overlay for super admins
      def crown?
        user.system_role == "super_admin"
      end
    end
  end
end
