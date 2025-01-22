FactoryBot.define do
  factory :user_membership do
    user
    subscription_type
    expiration_date { 1.year.from_now }
    status { true }
    
    trait :expired do
      expiration_date { 1.day.ago }
    end

    trait :inactive do
      status { false }
    end

    trait :with_payment do
      after(:create) do |membership|
        create(:payment, user: membership.user, user_membership: membership)
      end
    end
  end
end 