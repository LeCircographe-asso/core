FactoryBot.define do
  factory :session do
    association :user
    ip_address { '127.0.0.1' }
    user_agent { 'Mozilla/5.0 (Test Browser)' }
  end
end
