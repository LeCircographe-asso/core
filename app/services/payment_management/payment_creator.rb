module PaymentManagement
  class PaymentCreator < BaseService

    attribute :person_id, :integer
    attribute :amount_cents, :integer
    attribute :payment_method, :string
    attribute :recorded_by_id, :integer
    attribute :item_type, :string
    attribute :item_id, :integer
    attribute :description, :string
    attribute :notes, :string

    validates :person_id, presence: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :recorded_by_id, presence: true
    validates :item_type, presence: true
    # item_id optionnel pour donations (utilise payment.id)

    def call
      return failure("Invalid payment data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the person
          person = Person.find(person_id)
          recorded_by = User.find(recorded_by_id)

          # Create payment
          payment = person.payments.create!(
            total_cents: amount_cents,
            payment_method: payment_method,
            status: :success,
            recorded_by: recorded_by,
            notes: notes
          )

          # Create payment line
          if item_type == "Donation"
            # Pour les donations, lier au paiement lui-même (comme Person#create_donation!)
            payment.payment_lines.create!(
              item_type: "Payment", # PaymentLine utilise Payment comme item_type pour donations
              item_id: payment.id,
              amount_cents: amount_cents,
              description: description || "Donation"
            )
          else
            # Pour les autres types, utiliser l'item fourni
            payment.payment_lines.create!(
              item_type: item_type,
              item_id: item_id,
              amount_cents: amount_cents,
              description: description || "Paiement #{item_type.downcase}"
            )
          end

          success(payment: payment, payment_lines: payment.payment_lines, message: "Payment created successfully")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
