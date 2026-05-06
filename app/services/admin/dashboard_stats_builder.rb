# frozen_string_literal: true

module Admin
  module DashboardStatsBuilder
    def self.call
      active = Membership.active
      {
        memberships_active:      active.count,
        memberships_basic:       active.joins(:membership_type).where(membership_types: { category: "basic" }).count,
        memberships_circus:      active.joins(:membership_type).where(membership_types: { category: "circus" }).count,
        memberships_expiring_30: active.where("ended_at <= ?", 30.days.from_now).count,
        memberships_expired:     Membership.expired.count,
        contributions_active:    Contribution.active.count,
        persons:                 Person.count,
        users:                   User.count,
        revenue_month:           Payment.this_month.where(status: :success).sum(:total_cents) / 100.0,
        new_members_today:       Person.where(created_at: Date.current.all_day).count
      }
    end
  end
end
