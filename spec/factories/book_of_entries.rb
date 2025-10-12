FactoryBot.define do
  factory :book_of_entry do
    association :user
    association :product
    remaining { 10 }
    total_entry { 10 }
  end
end
