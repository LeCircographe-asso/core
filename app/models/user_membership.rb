class UserMembership < ApplicationRecord
  belongs_to :user
  belongs_to :membership
  enum :status, %i[active pending expired canceled]
end
