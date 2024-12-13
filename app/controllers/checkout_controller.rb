class CheckoutController < ApplicationController
  before_action :authenticated?
  def create
    @event = Event.find(params[:event_id])

    price_in_cents = 1000

    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [
        {
          price_data: {
            currency: "eur",
            unit_amount: price_in_cents,
            product_data: {
              name: "@event.title"
            }
          },
          quantity: 1
        }
      ],
      mode: "payment",
      success_url: "#{checkout_success_url}?session_id={CHECKOUT_SESSION_ID}&event_id=#{@event.id}",

      cancel_url: checkout_cancel_url,
      metadata: {
        
        event_id: @event.id,
        user_id: Current.user.id
      }
    )
    redirect_to session.url, allow_other_host: true
  end

  def success
    @session = Stripe::Checkout::Session.retrieve(params[:session_id])
    @event = Event.find(params[:event_id])
    @payment_intent = Stripe::PaymentIntent.retrieve(@session.payment_intent)

    if @payment_intent.status == "succeeded"
      EventAttendee.create!(user_id: Current.user.id, event_id: @event.id, payment_id: @payment_intent.id, interested: true)
      redirect_to @event, notice: "Paiement réussi et commande mise à jour."
    else
      redirect_to events_path, alert: "Paiement non réussi, commande non mise à jour."
    end
  end

  def cancel
    redirect_to events_path, alert: "Le paiement a été annulé."
  end
end
