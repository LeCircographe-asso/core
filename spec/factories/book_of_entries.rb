FactoryBot.define do
  factory :book_of_entry do
    association :person
    association :subscription_plan, factory: [:subscription_plan, :pack10]
    sessions_remaining { 10 }
    status { :active }
    purchased_at { Date.current }
    expires_at { Date.current + 1.year }

    trait :active do
      status { :active }
      sessions_remaining { 5 }
    end

    trait :inactive do
      status { :inactive }
      sessions_remaining { 0 }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.day.ago }
    end

    trait :consumed do
      status { :consumed }
      sessions_remaining { 0 }
    end
  end
end