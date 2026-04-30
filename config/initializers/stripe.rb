# frozen_string_literal: true

Rails.configuration.stripe = {
  publishable_key: ENV.fetch('PUBLISHABLE_KEY', nil),
  secret_key: ENV.fetch('SECRET_KEY', nil)
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
