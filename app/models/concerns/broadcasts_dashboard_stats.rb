# frozen_string_literal: true

# Shared concern — included in Membership, Contribution, Payment.
# Rebroadcasts the admin dashboard stats bar after any relevant commit.
module BroadcastsDashboardStats
  extend ActiveSupport::Concern

  private

  def broadcast_dashboard_stats
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin:dashboard",
      target: "dashboard-stats-bar",
      partial: "admin/dashboard/stats_bar",
      locals: { stats: Admin::DashboardStatsBuilder.call }
    )
  rescue => e
    Rails.logger.warn("[BroadcastsDashboardStats] broadcast skipped: #{e.message}")
  end
end
