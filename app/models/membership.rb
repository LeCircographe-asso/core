class Membership < ApplicationRecord
  enum :type_name, %i[No_Member Basic Circus], default: :No_Member
  has_many :user_memberships
  has_many :user, through: :user_memberships
end
