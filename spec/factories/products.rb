FactoryBot.define do
  factory :product do
    product_name { "Adhésion simple" }
    price { 10.0 }
    active { true }

    trait :circus_membership do
      product_name { "Adhésion Cirque - Tarif Plein" }
      price { 30.0 }
    end

    trait :basic_membership do
      product_name { "Adhésion simple" }
      price { 10.0 }
    end

    trait :annual_subscription do
      product_name { "Cotisation annuelle" }
      price { 250.0 }
    end

    trait :quarterly_subscription do
      product_name { "Cotisation trimestrielle" }
      price { 75.0 }
    end

    trait :ten_sessions do
      product_name { "Cotisation 10 séances" }
      price { 100.0 }
    end

    trait :day_pass do
      product_name { "Pass journée" }
      price { 15.0 }
    end

    trait :donation do
      product_name { "Donation" }
      price { 5.0 }
    end
  end
end
