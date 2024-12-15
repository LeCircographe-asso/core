class UserMembershipSubscription < ApplicationRecord
  belongs_to :user_membership
  belongs_to :subscription_type
end
