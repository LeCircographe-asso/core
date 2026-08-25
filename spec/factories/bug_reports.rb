# frozen_string_literal: true

FactoryBot.define do
  factory :bug_report do
    note { "Le bouton \"Renouveler\" ne répond pas sur mobile." }
    page_url { "https://lecircographe.fr/admin/members/123" }
    user_agent { "Mozilla/5.0" }

    trait :with_person do
      person
    end
  end
end
