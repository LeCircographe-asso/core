FactoryBot.define do
  factory :attendance do
    association :person
    association :event
    date { Date.current }

    trait :with_contribution do
      association :contribution
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :tomorrow do
      date { Date.tomorrow }
    end
  end
end
