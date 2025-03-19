class SubscriptionType < ApplicationRecord
  has_many :user_membership_subscriptions
  has_many :user_memberships, through: :user_membership_subscriptions
end
