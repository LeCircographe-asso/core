# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsletterSignupService do
  describe '#call_newsletter' do
    context 'when creating a new subscriber' do
      let(:email) { 'new@example.com' }

      it 'creates a new subscriber with source "web"' do
        result = NewsletterSignupService.new(email).call_newsletter

        expect(result[:success]).to be true
        expect(result[:message]).to eq('Inscription à la newsletter réussie !')

        subscriber = NewsletterSubscriber.find_by(email: email)
        expect(subscriber).to be_present
        expect(subscriber.subscribed).to be true
        expect(subscriber.source).to eq('web')
      end

      it 'normalizes email' do
        NewsletterSignupService.new('  NEW@EXAMPLE.COM  ').call_newsletter

        subscriber = NewsletterSubscriber.find_by(email: 'new@example.com')
        expect(subscriber).to be_present
      end

      context 'when person exists with matching email' do
        let(:auto_link_email) { 'autolink@example.com' }
        let!(:person) { create(:person, email: auto_link_email) }

        it 'auto-links subscriber to existing person' do
          result = NewsletterSignupService.new(auto_link_email).call_newsletter

          expect(result[:success]).to be true

          subscriber = NewsletterSubscriber.find_by(email: auto_link_email)
          expect(subscriber.person).to eq(person)
        end
      end

      context 'when person does not exist' do
        it 'creates orphaned subscriber' do
          result = NewsletterSignupService.new(email).call_newsletter

          expect(result[:success]).to be true

          subscriber = NewsletterSubscriber.find_by(email: email)
          expect(subscriber.person).to be_nil
        end
      end
    end

    context 'when subscriber already exists' do
      context 'currently subscribed' do
        let!(:subscriber) { create(:newsletter_subscriber, :subscribed, email: 'existing@example.com') }

        it 'redirects to login (must manage from profile)' do
          result = NewsletterSignupService.new('existing@example.com').call_newsletter

          expect(result[:success]).to be false
          expect(result[:redirect_to]).to be true
          expect(result[:message]).to include('déjà dans notre liste')

          subscriber.reload
          expect(subscriber.subscribed).to be true # Still subscribed
        end
      end

      context 'currently unsubscribed' do
        let!(:subscriber) { create(:newsletter_subscriber, :unsubscribed, email: 'unsubbed@example.com') }

        it 'redirects to login (must manage from profile)' do
          result = NewsletterSignupService.new('unsubbed@example.com').call_newsletter

          expect(result[:success]).to be false
          expect(result[:redirect_to]).to be true
          expect(result[:message]).to include('déjà dans notre liste')

          subscriber.reload
          expect(subscriber.subscribed).to be false # Still unsubscribed
        end
      end
    end
  end
end
