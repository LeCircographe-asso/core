FactoryBot.define do
  factory :order do
    association :user
    sum { 100.0 }
    date { Time.current }

    trait :with_products do
      after(:create) do |order|
        product = create(:product)
        create(:product_order, order: order, product: product, quantity: 1)
      end
    end
  end
end
