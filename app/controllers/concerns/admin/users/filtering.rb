module Admin
  module Users
    module Filtering
      extend ActiveSupport::Concern

      private

      def apply_person_filters
        case params[:filter]
        when "with_active_membership"
          @people = @people.with_active_membership
        when "with_expiring_membership"
          @people = @people.with_expiring_membership
        when "with_expired_membership"
          @people = @people.with_expired_membership
        when "without_membership"
          @people = @people.without_membership
        when "with_user_account"
          @people = @people.with_user_account
        when "without_user_account"
          @people = @people.without_user_account
        end
      end

      def apply_person_search
        @people = @people.search_by_contact(params[:search]) if params[:search].present?
      end
    end
  end
end
