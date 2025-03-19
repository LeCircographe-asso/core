class Payment < ApplicationRecord
  belongs_to :user, optional: true
end
