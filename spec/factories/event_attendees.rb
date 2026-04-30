# frozen_string_literal: true

FactoryBot.define do
  factory :event_attendee do
    association :user
    association :event
  end
end
