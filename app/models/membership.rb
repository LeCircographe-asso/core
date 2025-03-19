class Membership < ApplicationRecord

  enum :type_name %i[no_member basic circus]
  
end 