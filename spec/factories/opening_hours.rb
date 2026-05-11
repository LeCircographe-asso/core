# frozen_string_literal: true

FactoryBot.define do
  factory :opening_hour do
    day { :mardi }
    open_at { "14:00" }
    close_at { "22:00" }
    closed { false }
    association :updated_by_user, factory: :user

    trait :closed do
      closed { true }
      open_at { nil }
      close_at { nil }
    end
  end
end
