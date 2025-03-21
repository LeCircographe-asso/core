class Membership < ApplicationRecord

  enum :type_name, %i[no_member basic circus]
  has_many :user_memberships
  has_many :user, through: :user_memberships
end 
