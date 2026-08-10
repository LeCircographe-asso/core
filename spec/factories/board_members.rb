# frozen_string_literal: true

FactoryBot.define do
  factory :board_member do
    sequence(:name) { |n| "Membre CA #{n}" }
    role { "Membre CA" }
    bio { "Bénévole engagé·e." }
  end
end
