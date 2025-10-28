module Priceable
  extend ActiveSupport::Concern

  # Conversion centimes <-> euros
  def price_euros
    # Support pour différents noms de colonnes
    cents = if respond_to?(:price_cents)
              price_cents
            elsif respond_to?(:total_cents)
              total_cents
            elsif respond_to?(:amount_cents)
              amount_cents
            else
              0
            end
    cents / 100.0
  end

  def price_euros=(value)
    # Support pour différents noms de colonnes
    if respond_to?(:price_cents=)
      self.price_cents = (value.to_f * 100).round
    elsif respond_to?(:total_cents=)
      self.total_cents = (value.to_f * 100).round
    elsif respond_to?(:amount_cents=)
      self.amount_cents = (value.to_f * 100).round
    end
  end

  def formatted_price
    "#{price_euros}€"
  end

  def name_with_price
    "#{name} - #{formatted_price}"
  end

  # Méthodes de classe pour les conversions
  class_methods do
    def cents_to_euros(cents)
      cents / 100.0
    end

    def euros_to_cents(euros)
      (euros.to_f * 100).round
    end
  end
end
