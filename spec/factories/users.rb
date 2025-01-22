FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :guest }
    first_name { "John" }
    last_name { "Doe" }
    
    trait :membership do
      role { :membership }
    end
    
    trait :circus_membership do
      role { :circus_membership }
    end

    trait :with_active_membership do
      after(:create) do |user|
        create(:user_membership, 
          user: user,
          expiration_date: 1.year.from_now,
          status: true
        )
      end
    end
  end
end 