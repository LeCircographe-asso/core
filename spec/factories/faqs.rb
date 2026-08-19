# frozen_string_literal: true

FactoryBot.define do
  factory :faq do
    sequence(:question) { |n| "Question #{n} ?" }
    answer { "Réponse détaillée." }
    label { "general" }
  end
end
