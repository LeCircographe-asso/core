# frozen_string_literal: true

FactoryBot.define do
  factory :person do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    address { Faker::Address.full_address }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 80) }
    emergency_contact_name { Faker::Name.name }
    emergency_contact_phone { Faker::PhoneNumber.phone_number }
    notes { Faker::Lorem.paragraph }
    occupation { Faker::Job.title }
    specialty { Faker::Job.seniority }
    image_rights { [true, false].sample }
    get_involved { [true, false].sample }
    newsletter_subscribed { [true, false].sample }
    dyslexic_font { [true, false].sample }
    is_minor { false }

    trait :with_user do
      association :user
    end

    trait :with_member_number do
      sequence(:member_number) { |n| format('%02dU%03d', Date.current.year % 100, n + 100) }
    end

    trait :with_active_membership do
      after(:create) do |person|
        create(:membership, person: person, status: :active)
      end
    end

    trait :with_basic_membership do
      after(:create) do |person|
        membership_type = create(:membership_type, category: :basic)
        create(:membership, person: person, membership_type: membership_type, status: :active)
      end
    end

    trait :with_circus_membership do
      after(:create) do |person|
        membership_type = create(:membership_type, category: :circus)
        create(:membership, person: person, membership_type: membership_type, status: :active)
      end
    end

    trait :with_expiring_membership do
      after(:create) do |person|
        create(:membership, person: person, status: :active, started_at: 11.months.ago, ended_at: 15.days.from_now)
      end
    end

    trait :with_expired_membership do
      after(:create) do |person|
        create(:membership, person: person, status: :expired, started_at: 1.year.ago, ended_at: 1.day.ago)
      end
    end

    trait :without_membership do
      transient do
        skip_membership_validation { true }
      end

      after(:create) do |person, evaluator|
        person.skip_membership_validation = evaluator.skip_membership_validation
        person.memberships.destroy_all if person.memberships.any?
      end
    end

    trait :minor do
      is_minor { true }
      birth_date { Faker::Date.birthday(min_age: 8, max_age: 17) }
    end

    trait :adult do
      is_minor { false }
      birth_date { Faker::Date.birthday(min_age: 18, max_age: 80) }
    end

    trait :with_email do
      email { Faker::Internet.unique.email }
    end

    trait :with_phone do
      phone { Faker::PhoneNumber.phone_number }
    end

    trait :newsletter_subscribed do
      newsletter_subscribed { true }
      email { Faker::Internet.unique.email } # Email required when newsletter subscribed
    end

    trait :skip_membership_validation do
      skip_membership_validation { true }
    end
  end
end
