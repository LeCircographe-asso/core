# frozen_string_literal: true

FactoryBot.define do
  factory :payment_line do
    association :payment
    association :item, factory: :membership_type
    amount_cents { 2500 }
    description { "Ligne de paiement" }

    trait :for_membership_type do
      association :item, factory: :membership_type
    end

    trait :for_contribution_formula do
      association :item, factory: :contribution_formula
    end

    trait :for_membership do
      association :item, factory: :membership
    end

    trait :for_contribution do
      association :item, factory: :contribution
      person { item.person }
    end
  end
end
