FactoryBot.define do
  factory :payment do
    association :user
    association :order
    amount { 50.0 }
    status { :pending }
    payment_type { :credit_card }

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
      payment_type { :cash }
    end

    trait :credit_card do
      payment_type { :credit_card }
    end

    trait :check do
      payment_type { :check }
    end
  end
end
