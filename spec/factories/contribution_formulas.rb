FactoryBot.define do
  factory :contribution_formula do
    association :membership_type
    sequence(:name) { |n| "Test Plan #{n}" }
    duration { :day }
    price_cents { 800 }
    description { Faker::Lorem.paragraph }
    version { 1 }
    effective_from { Date.current }
    effective_until { nil }
    sessions_count { nil }
    validity_days { nil }

    trait :day do
      duration { :day }
      sequence(:name) { |n| "Journée #{n}" }
      price_cents { 800 }
      sessions_count { nil }
      validity_days { nil }
    end

    trait :trimester do
      duration { :trimester }
      sequence(:name) { |n| "Trimestre #{n}" }
      price_cents { 6000 }
      sessions_count { nil }
      validity_days { nil }
    end

    trait :annual do
      duration { :annual }
      sequence(:name) { |n| "Annuel #{n}" }
      price_cents { 20000 }
      sessions_count { nil }
      validity_days { nil }
    end

    trait :pack10 do
      duration { :pack10 }
      sequence(:name) { |n| "Pack 10 séances #{n}" }
      price_cents { 7000 }
      sessions_count { 10 }
      validity_days { 365 }
    end
  end
end
