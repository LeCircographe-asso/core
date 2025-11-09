require "ostruct"

module Admin
  class DashboardStatisticsService
    def initialize(base_people: nil)
      @base_people = base_people || PersonQuery.active.main_people
    end

    def call
      {
        total_people: total_people,
        people_with_user: people_with_user,
        people_without_user: people_without_user,
        new_users_yesterday: new_users_yesterday,
        basic_memberships: basic_memberships,
        circus_memberships: circus_memberships,
        active_memberships: active_memberships,
        users_this_month: users_this_month
      }
    end

    private

    attr_reader :base_people

    def total_people
      base_people.count
    end

    def people_with_user
      base_people.joins(:user).count
    end

    def people_without_user
      base_people.left_joins(:user).where(users: { id: nil }).count
    end

    def new_users_yesterday
      User.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).count
    end

    def basic_memberships
      Membership.joins(:membership_type).where(membership_types: { name: "Basic" }).count
    end

    def circus_memberships
      Membership.joins(:membership_type).where(membership_types: { name: "Cirque" }).count
    end

    def active_memberships
      Membership.active.count
    end

    def users_this_month
      User.this_month.count
    end
  end
end
