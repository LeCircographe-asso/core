FactoryBot.define do
  factory :product do
    product_name { "Adhésion simple" }
    product_type { "adhesion" }

    trait :circus_membership do
      product_name { "Adhésion Cirque - Tarif Plein" }
      product_type { "adhesion" }
    end

    trait :basic_membership do
      product_name { "Adhésion simple" }
      product_type { "adhesion" }
    end

    trait :annual_subscription do
      product_name { "Cotisation annuelle" }
      product_type { "cotisation" }
    end

    trait :quarterly_subscription do
      product_name { "Cotisation trimestrielle" }
      product_type { "cotisation" }
    end

    trait :ten_sessions do
      product_name { "Cotisation 10 séances" }
      product_type { "cotisation" }
    end

    trait :day_pass do
      product_name { "Pass journée" }
      product_type { "pass" }
    end

    trait :donation do
      product_name { "Donation" }
      product_type { "donation" }
    end

    trait :with_price do
      after(:create) do |product|
        create(:price_entry, product: product, price: 10.0)
      end
    end
  end
end
