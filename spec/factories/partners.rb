# frozen_string_literal: true

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Partenaire #{n}" }
    category { "Compagnie" }
    bio { "Partenaire du Circographe." }
  end
end
