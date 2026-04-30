# frozen_string_literal: true

class MembershipExpirationReminderJob < ApplicationJob
  queue_as :default

  def perform
    memberships = Membership.active.where(ended_at: 30.days.from_now.to_date)

    memberships.each do |membership|
      UserMailer.membership_expiration_reminder(membership).deliver_later
    end
  end
end
