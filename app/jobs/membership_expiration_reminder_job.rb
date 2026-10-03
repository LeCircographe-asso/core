# frozen_string_literal: true

class MembershipExpirationReminderJob < ApplicationJob
  queue_as :default

  def perform
    memberships = Membership.active.where(ended_at: 30.days.from_now.to_date).includes(:person)

    memberships.each do |membership|
      next if membership.person&.email.blank?

      UserMailer.membership_expiration_reminder(membership).deliver_later
    end
  end
end
