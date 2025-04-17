FactoryBot.define do
  factory :product_order do
    association :product
    association :order
    association :user
    quantity { 1 }
    unit_price { 10.0 }
    
    trait :with_basic_membership do
      association :product, factory: [:product, :basic_membership]
    end
    
    trait :with_circus_membership do
      association :product, factory: [:product, :circus_membership]
    end
    
    trait :with_annual_subscription do
      association :product, factory: [:product, :annual_subscription]
    end
    
    trait :with_quarterly_subscription do
      association :product, factory: [:product, :quarterly_subscription]
    end
    
    trait :with_ten_sessions do
      association :product, factory: [:product, :ten_sessions]
    end
    
    trait :with_day_pass do
      association :product, factory: [:product, :day_pass]
    end
    
    trait :with_donation do
      association :product, factory: [:product, :donation]
    end
  end
end 