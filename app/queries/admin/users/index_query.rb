# frozen_string_literal: true

module Admin
  module Users
    class IndexQuery
      def initialize(params)
        @params = params
      end

      def call
        apply_sort(apply_search(apply_filter(base_query)))
      end

      private

      attr_reader :params

      def base_query
        PersonQuery.active.main_people.includes(
          :user,
          memberships: :membership_type,
          contributions: :contribution_formula
        )
      end

      def apply_filter(relation)
        case params[:filter]
        when "with_active_membership"
          relation.with_active_membership
        when "with_expiring_membership"
          relation.with_expiring_membership
        when "with_expired_membership"
          relation.with_expired_membership
        when "without_membership"
          relation.without_membership
        when "with_user_account"
          relation.with_user_account
        when "without_user_account"
          relation.without_user_account
        else
          relation
        end
      end

      def apply_search(relation)
        return relation if params[:search].blank?

        relation.search_by_contact(params[:search])
      end

      def apply_sort(relation)
        relation.order(:last_name, :first_name)
      end
    end
  end
end
