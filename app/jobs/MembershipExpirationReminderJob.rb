class MembershipExpirationReminderJob < ApplicationJob
  queue_as :default

  def perform
    # find all membership expirying within 30 days
    user_memberships = UserMembership.where(end_date: 30.days.from_now.to_date)

    # send email for each memberships
    user_memberships.each do |user_membership|
      UserMailer.membership_expiration_reminder(user_membership).deliver_later
    end
  end
end
