# frozen_string_literal: true

FactoryBot.define do
  factory :person do
    sequence(:first_name) { |n| "Prenom#{n}" }
    sequence(:last_name) { |n| "Nom#{n}" }
    sequence(:email) { |n| "person#{n}@example.test" }
    sequence(:phone) { |n| "060000#{format('%04d', n)}" }
    address { '1 rue de Test' }
    birth_date { Date.new(1990, 1, 1) }
    emergency_contact_name { 'Contact Test' }
    emergency_contact_phone { '0600000000' }
    notes { 'Note de test' }
    occupation { 'Artiste' }
    specialty { 'Generaliste' }
    image_rights { false }
    get_involved { false }
    newsletter_subscribed { false }
    dyslexic_font { false }
    is_minor { false }

    trait :with_user do
      after(:create) do |person|
        create(:user, person: person, email_address: person.email)
      end
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
      birth_date { 12.years.ago.to_date }
    end

    trait :adult do
      is_minor { false }
      birth_date { Date.new(1990, 1, 1) }
    end

    trait :with_email do
      sequence(:email) { |n| "person-with-email#{n}@example.test" }
    end

    trait :with_phone do
      sequence(:phone) { |n| "070000#{format('%04d', n)}" }
    end

    trait :newsletter_subscribed do
      newsletter_subscribed { true }
      sequence(:email) { |n| "newsletter#{n}@example.test" } # Email required when newsletter subscribed
    end

    trait :skip_membership_validation do
      skip_membership_validation { true }
    end
  end
end
