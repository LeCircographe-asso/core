FactoryBot.define do
  factory :payment_audit_log do
    association :payment
    action { 'create' }
    user { nil }
    change_data { {} }
    created_at { Time.current }

    trait :status_change do
      action { 'status_change' }
      change_data do
        {
          status: {
            from: 'pending',
            to: 'success'
          }
        }
      end
    end

    trait :user_deleted do
      action { 'user_deleted' }
      user { nil }
    end

    trait :delete do
      action { 'delete' }
    end
  end
end
