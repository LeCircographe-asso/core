FactoryBot.define do
  factory :account_claim do
    association :person
    user { nil } # Optional association
    status { :pending }
    expires_at { 7.days.from_now }

    trait :with_user do
      association :user
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :rejected do
      status { :rejected }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.day.ago }
    end
  end
end
