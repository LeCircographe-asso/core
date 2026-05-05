# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Checkout', type: :request do
  describe 'POST /checkout' do
    context 'when not authenticated' do
      let(:event) { create(:event) }

      it 'redirects to login' do
        post checkout_create_path, params: { event_id: event.id }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when authenticated' do
      let(:user) { create(:user) }
      let(:event) { create(:event) }

      before { login_as(user) }

      it 'creates a Stripe checkout session' do
        expect(Stripe::Checkout::Session).to receive(:create).with(
          payment_method_types: [ 'card' ],
          line_items: [
            {
              price_data: {
                currency: 'eur',
                unit_amount: 1000,
                product_data: {
                  name: '@event.title'
                }
              },
              quantity: 1
            }
          ],
          mode: 'payment',
          success_url: "#{checkout_success_url}?session_id={CHECKOUT_SESSION_ID}&event_id=#{event.id}",
          cancel_url: checkout_cancel_url,
          metadata: {
            event_id: event.id,
            user_id: user.id
          }
        ).and_return(double(url: 'https://checkout.stripe.com/test-session'))

        post checkout_create_path, params: { event_id: event.id }
        expect(response.status).to eq(302)
      end

      it 'redirects to Stripe checkout url' do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(
          double(url: 'https://checkout.stripe.com/test-session')
        )

        post checkout_create_path, params: { event_id: event.id }
        expect(response).to redirect_to('https://checkout.stripe.com/test-session')
      end
    end
  end

  describe 'GET /checkout/success' do
    context 'when authenticated' do
      let(:user) { create(:user) }
      let(:event) { create(:event) }
      let(:session) { double(id: 'test_session', payment_intent: 'test_intent') }

      before { login_as(user) }

      context 'with successful payment' do
        let(:payment_intent) { double(status: 'succeeded') }

        it 'creates an event attendee' do
          allow(Stripe::Checkout::Session).to receive(:retrieve).with('test_session').and_return(session)
          allow(Stripe::PaymentIntent).to receive(:retrieve).with('test_intent').and_return(payment_intent)

          expect do
            get checkout_success_path, params: { session_id: 'test_session', event_id: event.id }
          end.to change { EventAttendee.count }.by(1)
        end

        it 'redirects to event with success notice' do
          allow(Stripe::Checkout::Session).to receive(:retrieve).with('test_session').and_return(session)
          allow(Stripe::PaymentIntent).to receive(:retrieve).with('test_intent').and_return(payment_intent)

          get checkout_success_path, params: { session_id: 'test_session', event_id: event.id }
          expect(response).to redirect_to(event_path(event))
        end
      end

      context 'with failed payment' do
        let(:payment_intent) { double(status: 'processing') }

        it 'does not create an event attendee' do
          allow(Stripe::Checkout::Session).to receive(:retrieve).with('test_session').and_return(session)
          allow(Stripe::PaymentIntent).to receive(:retrieve).with('test_intent').and_return(payment_intent)

          expect do
            get checkout_success_path, params: { session_id: 'test_session', event_id: event.id }
          end.not_to(change { EventAttendee.count })
        end

        it 'redirects to events with error message' do
          allow(Stripe::Checkout::Session).to receive(:retrieve).with('test_session').and_return(session)
          allow(Stripe::PaymentIntent).to receive(:retrieve).with('test_intent').and_return(payment_intent)

          get checkout_success_path, params: { session_id: 'test_session', event_id: event.id }
          expect(response).to redirect_to(actualites_path(anchor: 'evenements'))
        end
      end
    end
  end

  describe 'GET /checkout/cancel' do
    context 'when authenticated' do
      let(:user) { create(:user) }

      before { login_as(user) }

      it 'redirects to events with cancel message' do
        get checkout_cancel_path
        expect(response).to redirect_to(actualites_path(anchor: 'evenements'))
        follow_redirect!
        expect(response.body).to include('annulé')
      end
    end
  end
end
