class UserMembership < ApplicationRecord

  enum :status, %i[active pending expired canceled]
  belongs_to :membership
  belongs_to :user
  belongs_to :produit, optional: true
  belongs_to :order, optional: true


end 