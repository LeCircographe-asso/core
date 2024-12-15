class Payment < ApplicationRecord
  has_many :users, through: :donations, dependent: :destroy
end
