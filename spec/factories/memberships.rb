FactoryBot.define do
  factory :membership do
    association :person
    association :membership_type
    started_at { Date.current }
    ended_at { Date.current + 1.year }
    status { :active }
    first_joined_at { Date.current }

    trait :active do
      status { :active }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :pending do
      status { :pending }
    end

    trait :expired do
      status { :expired }
      ended_at { 1.day.ago }
    end

    trait :basic do
      association :membership_type, category: :basic
    end

    trait :circus_full do
      association :membership_type, category: :circus, name: 'Adhésion Cirque Complète', price_cents: 2500
    end

    trait :circus_reduced do
      association :membership_type, category: :circus, name: 'Adhésion Cirque Réduite', price_cents: 2000
    end

    trait :current do
      started_at { Date.current - 1.month }
      ended_at { Date.current + 11.months }
    end

    trait :future do
      started_at { Date.current + 1.month }
      ended_at { Date.current + 13.months }
    end

    trait :past do
      started_at { Date.current - 1.year }
      ended_at { Date.current - 1.month }
    end

    trait :expiring do
      started_at { Date.current - 11.months }
      ended_at { Date.current + 1.month }
    end

    trait :recently_started do
      started_at { Date.current - 1.week }
      ended_at { Date.current + 51.weeks }
    end
  end
end
