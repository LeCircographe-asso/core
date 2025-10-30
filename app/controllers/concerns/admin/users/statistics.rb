module Admin
  module Users
    module Statistics
      extend ActiveSupport::Concern

      private

      def load_dashboard_statistics
        @total_people = Person.main_people.count
        @people_with_user = Person.main_people.joins(:user).count
        @people_without_user = Person.main_people.left_joins(:user).where(users: { id: nil }).count
        @new_users_yesterday = UserService.new_users_count
        @basic_memberships = MembershipService.membership_type_count(:Basic)
        @circus_memberships = MembershipService.membership_type_count(:Circus)
        @active_memberships = MembershipService.active_memberships_count
        @users_this_month = UserService.users_this_month
      end
    end
  end
end
