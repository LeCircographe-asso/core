# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsletterSubscriber, type: :model do
  describe 'validations' do
    it 'can be created' do
      subscriber = NewsletterSubscriber.new(
        email: 'test@example.com',
        subscribed: true,
        source: 'web'
      )
      expect(subscriber).to be_present
    end

    it 'requires email' do
      subscriber = NewsletterSubscriber.new(subscribed: true, source: 'web')
      expect(subscriber).not_to be_valid
      expect(subscriber.errors[:email]).to include("can't be blank")
    end

    it 'requires valid email format' do
      subscriber = NewsletterSubscriber.new(email: 'invalid-email', subscribed: true, source: 'web')
      expect(subscriber).not_to be_valid
      expect(subscriber.errors[:email]).to be_present
    end

    it 'requires unique email' do
      create(:newsletter_subscriber, email: 'test@example.com')

      duplicate = NewsletterSubscriber.new(email: 'test@example.com', subscribed: true, source: 'web')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been taken')
    end

    it 'defaults to subscribed' do
      subscriber = create(:newsletter_subscriber)
      expect(subscriber.subscribed).to be true
    end
  end

  describe 'associations' do
    it 'belongs to person (optional)' do
      person = create(:person)
      subscriber = create(:newsletter_subscriber, person: person)
      expect(subscriber.person).to eq(person)
    end

    it 'can exist without person' do
      subscriber = create(:newsletter_subscriber, :orphaned)
      expect(subscriber.person).to be_nil
    end
  end

  describe 'scopes' do
    let!(:subscribed_subscriber) { create(:newsletter_subscriber, :subscribed) }
    let!(:unsubscribed_subscriber) { create(:newsletter_subscriber, :unsubscribed) }
    let!(:orphaned_subscriber) { create(:newsletter_subscriber, :orphaned) }
    let!(:linked_subscriber) { create(:newsletter_subscriber, :with_person) }

    it 'finds subscribed subscribers' do
      expect(NewsletterSubscriber.subscribed).to include(subscribed_subscriber)
      expect(NewsletterSubscriber.subscribed).not_to include(unsubscribed_subscriber)
    end

    it 'finds unsubscribed subscribers' do
      expect(NewsletterSubscriber.unsubscribed).to include(unsubscribed_subscriber)
      expect(NewsletterSubscriber.unsubscribed).not_to include(subscribed_subscriber)
    end

    it 'finds orphaned subscribers' do
      expect(NewsletterSubscriber.orphaned).to include(orphaned_subscriber)
      expect(NewsletterSubscriber.orphaned).not_to include(linked_subscriber)
    end

    it 'finds linked subscribers' do
      expect(NewsletterSubscriber.linked).to include(linked_subscriber)
      expect(NewsletterSubscriber.linked).not_to include(orphaned_subscriber)
    end
  end

  describe 'callbacks' do
    it 'generates unsubscribe_token before create' do
      subscriber = NewsletterSubscriber.new(email: 'test@example.com', subscribed: true, source: 'web')
      expect(subscriber.unsubscribe_token).to be_nil

      subscriber.save!

      expect(subscriber.unsubscribe_token).to be_present
    end

    it 'sets subscribed_at before create' do
      subscriber = NewsletterSubscriber.new(email: 'test@example.com', subscribed: true, source: 'web')
      expect(subscriber.subscribed_at).to be_nil

      subscriber.save!

      expect(subscriber.subscribed_at).to be_present
    end

    it 'normalizes email before validation' do
      subscriber = NewsletterSubscriber.new(email: '  TEST@EXAMPLE.COM  ', subscribed: true, source: 'web')
      subscriber.valid?

      expect(subscriber.email).to eq('test@example.com')
    end
  end

  describe '#unsubscribe!' do
    it 'marks subscriber as unsubscribed' do
      subscriber = create(:newsletter_subscriber, :subscribed)

      subscriber.unsubscribe!

      expect(subscriber.subscribed).to be false
      expect(subscriber.unsubscribed_at).to be_present
    end
  end

  describe '#resubscribe!' do
    it 'marks subscriber as subscribed' do
      subscriber = create(:newsletter_subscriber, :unsubscribed)

      subscriber.resubscribe!

      expect(subscriber.subscribed).to be true
      expect(subscriber.subscribed_at).to be_present
      expect(subscriber.unsubscribed_at).to be_nil
    end
  end

  describe '#link_to_person!' do
    let(:person) { create(:person) }
    let(:subscriber) { create(:newsletter_subscriber, :orphaned) }

    it 'links subscriber to person' do
      subscriber.link_to_person!(person)

      expect(subscriber.person).to eq(person)
    end
  end

  describe 'Dateable concern methods' do
    let(:subscriber) { create(:newsletter_subscriber, subscribed_at: Date.current.beginning_of_day + 12.hours) }

    describe '#formatted_date' do
      it 'formats subscribed_at date' do
        formatted = subscriber.formatted_date(:subscribed_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4}})
      end

      it 'formats unsubscribed_at date' do
        unsubscribed = create(:newsletter_subscriber, :unsubscribed, unsubscribed_at: Date.current.beginning_of_day + 14.hours)
        formatted = unsubscribed.formatted_date(:unsubscribed_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4}})
      end
    end

    describe '#formatted_datetime' do
      it 'formats subscribed_at datetime' do
        formatted = subscriber.formatted_datetime(:subscribed_at)
        expect(formatted).to match(%r{\d{2}/\d{2}/\d{4} à \d{2}:\d{2}})
      end
    end

    describe '#today?' do
      it 'returns true for subscriber subscribed today' do
        expect(subscriber.today?(:subscribed_at)).to be true
      end

      it 'returns false for subscriber subscribed yesterday' do
        old_subscriber = create(:newsletter_subscriber, subscribed_at: Date.yesterday.beginning_of_day + 12.hours)
        expect(old_subscriber.today?(:subscribed_at)).to be false
      end
    end

    describe '#this_week?' do
      it 'returns true for subscriber subscribed this week' do
        expect(subscriber.this_week?(:subscribed_at)).to be true
      end
    end

    describe '#this_month?' do
      it 'returns true for subscriber subscribed this month' do
        expect(subscriber.this_month?(:subscribed_at)).to be true
      end
    end

    describe '#duration_days' do
      it 'calculates duration between subscribed_at and unsubscribed_at' do
        subscriber = create(:newsletter_subscriber,
                            subscribed_at: Date.current - 30.days,
                            unsubscribed_at: Date.current)
        expect(subscriber.duration_days(:subscribed_at, :unsubscribed_at)).to eq(30)
      end
    end
  end
end
