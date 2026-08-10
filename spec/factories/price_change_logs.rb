# frozen_string_literal: true

FactoryBot.define do
  factory :price_change_log do
    association :loggable, factory: :membership_type
    action { 'merged' }
    user { nil }
    change_data { {} }
    created_at { Time.current }

    trait :versioned do
      action { 'versioned' }
    end

    trait :archived do
      action { 'archived' }
    end
  end
end
