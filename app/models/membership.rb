class Membership < ApplicationRecord

  enum :type_name {no_member: 0, basic: 1, circus: 2} default: 0
  
end 