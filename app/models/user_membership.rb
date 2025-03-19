class UserMembership < ApplicationRecord

  enum :status, {active: 0, pending: 1, expired: 2, canceled: 3} 
  
end 