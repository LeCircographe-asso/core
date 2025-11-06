FactoryBot.define do
  factory :book_of_entry do
    association :person
    association :subscription_plan, factory: [:subscription_plan, :pack10]
    sessions_remaining { subscription_plan.sessions_count || 10 }
    status { :active }
    purchased_at { Time.current }
    expires_at { nil }

    trait :active do
      status { :active }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.day.ago }
    end

    trait :consumed do
      status { :consumed }
      sessions_remaining { 0 }
    end

    trait :with_sessions do
      sessions_remaining { 5 }
    end

    trait :empty do
      sessions_remaining { 0 }
    end
  end
end