FactoryBot.define do
  factory :payment do
    association :person
    association :recorded_by, factory: :user
    total_cents { 1500 }
    status { :pending }
    payment_method { :cash }

    trait :success do
      status { :success }
    end

    trait :pending do
      status { :pending }
    end

    trait :cancel do
      status { :cancel }
    end

    trait :cash do
      payment_method { :cash }
    end

    trait :card do
      payment_method { :card }
    end

    trait :cheque do
      payment_method { :cheque }
    end

    trait :transfer do
      payment_method { :transfer }
    end

    trait :offered do
      payment_method { :offered }
    end

    trait :with_membership_line do
      after(:create) do |payment|
        membership = create(:membership, person: payment.person)
        create(:payment_line, payment: payment, item: membership, item_type: "Membership", amount_cents: payment.total_cents)
      end
    end

    trait :with_contribution_formula_line do
      after(:create) do |payment|
        contribution_formula = create(:contribution_formula)
        create(:payment_line, payment: payment, item: contribution_formula, item_type: "ContributionFormula", amount_cents: payment.total_cents)
      end
    end

    trait :with_membership_type_line do
      after(:create) do |payment|
        membership_type = create(:membership_type)
        create(:payment_line, payment: payment, item: membership_type, item_type: "MembershipType", amount_cents: payment.total_cents)
      end
    end

    trait :with_donation do
      donation { 500 } # 5€ donation
    end

    trait :recent do
      created_at { 1.hour.ago }
    end

    trait :old do
      created_at { 25.hours.ago }
    end
  end
end
