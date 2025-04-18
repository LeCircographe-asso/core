FactoryBot.define do
  factory :user_membership do
    association :user
    association :membership
    status { :pending }

    trait :active do
      status { :active }
    end

    trait :expired do
      status { :expired }
    end

    trait :canceled do
      status { :canceled }
    end
  end
end
