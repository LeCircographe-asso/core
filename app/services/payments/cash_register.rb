module Payments
  class CashRegister
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person_id, :integer
    attribute :recorded_by_id, :integer
    attribute :payment_method, :string, default: 'cash'
    attribute :notes, :string
    attribute :items, default: -> { [] }

    validates :person_id, presence: true
    validates :recorded_by_id, presence: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :items, presence: true

    def initialize(attributes = {})
      super
      @person = Person.find(person_id) if person_id.present?
      @recorded_by = User.find(recorded_by_id) if recorded_by_id.present?
    end

    def call
      return failure("Invalid attributes") unless valid?

      ActiveRecord::Base.transaction do
        create_payment
        create_payment_lines
        process_payment
        success
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    attr_reader :person, :recorded_by, :payment

    def create_payment
      @payment = Payment.create!(
        person: person,
        recorded_by: recorded_by,
        total_cents: calculate_total_cents,
        payment_method: payment_method,
        status: payment_method == 'offered' ? 'success' : 'pending',
        notes: notes
      )
    end

    def create_payment_lines
      items.each do |item|
        PaymentLine.create!(
          payment: payment,
          item: item[:object],
          amount_cents: item[:amount_cents],
          description: item[:description]
        )
      end
    end

    def process_payment
      return if payment_method == 'offered'

      # Pour les autres méthodes de paiement, on peut ajouter une logique
      # de traitement (vérification CB, validation chèque, etc.)
      payment.update!(status: 'success')
    end

    def calculate_total_cents
      items.sum { |item| item[:amount_cents] }
    end

    def success
      OpenStruct.new(success?: true, payment: payment, message: "Paiement enregistré avec succès")
    end

    def failure(message)
      OpenStruct.new(success?: false, payment: nil, message: message)
    end

    # Méthodes de classe pour faciliter l'utilisation
    def self.register_membership_payment(person:, membership_type:, recorded_by:, payment_method: 'cash', notes: nil)
      new(
        person_id: person.id,
        recorded_by_id: recorded_by.id,
        payment_method: payment_method,
        notes: notes,
        items: [
          {
            object: membership_type,
            amount_cents: membership_type.price_cents,
            description: "Adhésion #{membership_type.name}"
          }
        ]
      ).call
    end

    def self.register_subscription_payment(person:, subscription_plan:, recorded_by:, payment_method: 'cash', notes: nil)
      new(
        person_id: person.id,
        recorded_by_id: recorded_by.id,
        payment_method: payment_method,
        notes: notes,
        items: [
          {
            object: subscription_plan,
            amount_cents: subscription_plan.price_cents,
            description: "#{subscription_plan.name} (#{subscription_plan.duration})"
          }
        ]
      ).call
    end

    def self.register_mixed_payment(person:, items:, recorded_by:, payment_method: 'cash', notes: nil)
      new(
        person_id: person.id,
        recorded_by_id: recorded_by.id,
        payment_method: payment_method,
        notes: notes,
        items: items
      ).call
    end
  end
end
