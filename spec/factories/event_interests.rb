# frozen_string_literal: true

FactoryBot.define do
  factory :event_interest do
    association :person
    association :event
  end
end
