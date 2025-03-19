class BookOfEntry < ApplicationRecord
  belongs_to :product
  belongs_to :user
end
