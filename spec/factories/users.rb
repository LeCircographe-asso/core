FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    cgu { true }
    privacy_policy { true }
    system_role { :web_visitor }

    trait :admin do
      system_role { :admin }
    end

    trait :super_admin do
      system_role { :super_admin }
    end

    trait :volunteer do
      system_role { :volunteer }
    end
  end
end
