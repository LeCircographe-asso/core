require 'rails_helper'

RSpec.describe NewsletterSignupService do
  describe '#call_newsletter' do
    context 'when creating a new subscriber' do
      let(:email) { 'new@example.com' }

      context 'anonymous user (web)' do
        it 'creates a new subscriber with source "web"' do
          result = NewsletterSignupService.new(email, nil).call_newsletter

          expect(result[:success]).to be true
          expect(result[:message]).to eq("Inscription à la newsletter réussie !")
          
          subscriber = NewsletterSubscriber.find_by(email: email)
          expect(subscriber).to be_present
          expect(subscriber.subscribed).to be true
          expect(subscriber.source).to eq('web')
        end

        it 'normalizes email' do
          NewsletterSignupService.new('  NEW@EXAMPLE.COM  ', nil).call_newsletter
          
          subscriber = NewsletterSubscriber.find_by(email: 'new@example.com')
          expect(subscriber).to be_present
        end
      end

      context 'authenticated regular user' do
        let(:user) { create(:user, system_role: :web_visitor) }

        it 'creates a new subscriber with source "authenticated"' do
          result = NewsletterSignupService.new(email, user).call_newsletter

          expect(result[:success]).to be true
          
          subscriber = NewsletterSubscriber.find_by(email: email)
          expect(subscriber.source).to eq('authenticated')
        end
      end

      context 'authenticated admin' do
        let(:admin) { create(:user, system_role: :admin) }

        it 'creates a new subscriber with source "admin"' do
          result = NewsletterSignupService.new(email, admin).call_newsletter

          expect(result[:success]).to be true
          
          subscriber = NewsletterSubscriber.find_by(email: email)
          expect(subscriber.source).to eq('admin')
        end
      end

      context 'authenticated super_admin' do
        let(:super_admin) { create(:user, system_role: :super_admin) }

        it 'creates a new subscriber with source "admin"' do
          result = NewsletterSignupService.new(email, super_admin).call_newsletter

          expect(result[:success]).to be true
          
          subscriber = NewsletterSubscriber.find_by(email: email)
          expect(subscriber.source).to eq('admin')
        end
      end

      context 'when person exists with matching email' do
        let(:auto_link_email) { 'autolink@example.com' }
        let!(:person) { create(:person, email: auto_link_email) }

        it 'auto-links subscriber to existing person' do
          result = NewsletterSignupService.new(auto_link_email, nil).call_newsletter

          expect(result[:success]).to be true
          
          subscriber = NewsletterSubscriber.find_by(email: auto_link_email)
          expect(subscriber.person).to eq(person)
        end
      end

      context 'when person does not exist' do
        it 'creates orphaned subscriber' do
          result = NewsletterSignupService.new(email, nil).call_newsletter

          expect(result[:success]).to be true
          
          subscriber = NewsletterSubscriber.find_by(email: email)
          expect(subscriber.person).to be_nil
        end
      end
    end

    context 'when subscriber already exists' do
      context 'currently subscribed' do
        let!(:subscriber) { create(:newsletter_subscriber, :subscribed, email: 'existing@example.com') }

        it 'unsubscribes the subscriber' do
          result = NewsletterSignupService.new('existing@example.com', nil).call_newsletter

          expect(result[:success]).to be true
          expect(result[:message]).to eq("Vous êtes désinscrit de la newsletter.")
          
          subscriber.reload
          expect(subscriber.subscribed).to be false
          expect(subscriber.unsubscribed_at).to be_present
        end
      end

      context 'currently unsubscribed' do
        let!(:subscriber) { create(:newsletter_subscriber, :unsubscribed, email: 'unsubbed@example.com') }

        it 'resubscribes the subscriber' do
          result = NewsletterSignupService.new('unsubbed@example.com', nil).call_newsletter

          expect(result[:success]).to be true
          expect(result[:message]).to eq("Vous êtes de nouveau inscrit à la newsletter.")
          
          subscriber.reload
          expect(subscriber.subscribed).to be true
          expect(subscriber.subscribed_at).to be_present
          expect(subscriber.unsubscribed_at).to be_nil
        end
      end
    end
  end

  describe '#determine_source' do
    context 'anonymous user' do
      it 'returns "web"' do
        service = NewsletterSignupService.new('test@example.com', nil)
        expect(service.send(:determine_source)).to eq('web')
      end
    end

    context 'authenticated regular user' do
      let(:user) { create(:user, system_role: :web_visitor) }

      it 'returns "authenticated"' do
        service = NewsletterSignupService.new('test@example.com', user)
        expect(service.send(:determine_source)).to eq('authenticated')
      end
    end

    context 'admin user' do
      let(:admin) { create(:user, system_role: :admin) }

      it 'returns "admin"' do
        service = NewsletterSignupService.new('test@example.com', admin)
        expect(service.send(:determine_source)).to eq('admin')
      end
    end

    context 'super_admin user' do
      let(:super_admin) { create(:user, system_role: :super_admin) }

      it 'returns "admin"' do
        service = NewsletterSignupService.new('test@example.com', super_admin)
        expect(service.send(:determine_source)).to eq('admin')
      end
    end
  end
end

