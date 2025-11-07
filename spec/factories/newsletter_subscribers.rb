FactoryBot.define do
  factory :newsletter_subscriber do
    sequence(:email) { |n| "subscriber#{n}@example.com" }
    subscribed { true }
    source { 'web' }

    trait :subscribed do
      subscribed { true }
      subscribed_at { Time.current }
    end

    trait :unsubscribed do
      subscribed { false }
      unsubscribed_at { Time.current }
    end

    trait :with_person do
      association :person
    end

    trait :orphaned do
      person { nil }
    end
  end
end
