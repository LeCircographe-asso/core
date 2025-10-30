FactoryBot.define do
  factory :subscription_plan do
    association :membership_type
    name { "#{duration.to_s.humanize} Plan" }
    duration { [ :day, :trimester, :annual, :pack10 ].sample }
    price_cents { [ 800, 6000, 20000, 7000 ].sample }
    description { Faker::Lorem.paragraph }
    version { 1 }
    effective_from { Date.current }
    effective_until { nil }
    sessions_count { duration == :pack10 ? 10 : nil }
    validity_days { duration == :pack10 ? 365 : nil }

    trait :day do
      duration { :day }
      name { "Journée" }
      price_cents { 800 }
      sessions_count { nil }
      validity_days { nil }
    end

    trait :trimester do
      duration { :trimester }
      name { "Trimestre" }
      price_cents { 6000 }
      sessions_count { nil }
      validity_days { nil }
    end

    trait :annual do
      duration { :annual }
      name { "Annuel" }
      price_cents { 20000 }
      sessions_count { nil }
      validity_days { nil }
    end

    trait :pack10 do
      duration { :pack10 }
      name { "Pack 10 séances" }
      price_cents { 7000 }
      sessions_count { 10 }
      validity_days { 365 }
    end
  end
end
