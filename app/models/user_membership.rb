class UserMembership < ApplicationRecord
  enum :status, %i[active pending expired canceled]
end
