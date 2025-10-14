FactoryBot.define do
  factory :attendance do
    association :person
    association :event
    date { Date.current }

    trait :with_book_of_entry do
      association :book_of_entry
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :tomorrow do
      date { Date.tomorrow }
    end
  end
end
