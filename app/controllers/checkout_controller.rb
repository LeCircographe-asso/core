class CheckoutController < ApplicationController
  def create
    @order = Order.find(params[:order_id])

    @total = (params[:total].to_d * 100).to_i

    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [
        {
          price_data: {
            currency: "eur",
            unit_amount: @total,
            product_data: {
              name: "Rails Stripe Checkout"
            }
          },
          quantity: 1
        }
      ],
      mode: "payment",
      success_url: "#{checkout_success_url}?session_id={CHECKOUT_SESSION_ID}&order_id=#{@order.id}",

      cancel_url: checkout_cancel_url,
      metadata: {
        order_id: @order.id
      }
    )
    redirect_to session.url, allow_other_host: true
  end

  def success
    @session = Stripe::Checkout::Session.retrieve(params[:session_id])
    @order = Order.find(params[:order_id])
    @payment_intent = Stripe::PaymentIntent.retrieve(@session.payment_intent)

    if @payment_intent.status == "succeeded"
      @order.update(status: "paid")
      redirect_to order_path(@order), notice: "Paiement réussi et commande mise à jour."
    else
      redirect_to orders_path, alert: "Paiement non réussi, commande non mise à jour."
    end
  end

  def cancel
  end
end
