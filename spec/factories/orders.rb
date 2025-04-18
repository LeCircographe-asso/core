FactoryBot.define do
  factory :order do
    association :user
    sum { 100.0 }
    status { :pending }

    trait :completed do
      status { :completed }
    end

    trait :pending do
      status { :pending }
    end

    trait :canceled do
      status { :canceled }
    end
  end
end
