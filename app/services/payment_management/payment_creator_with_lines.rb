module PaymentManagement
  class PaymentCreatorWithLines < BaseService

    attribute :person_id, :integer
    attribute :total_cents, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :payment_lines, array: true, default: []
    attribute :notes, :string

    validates :person_id, presence: true
    validates :total_cents, presence: true, numericality: { greater_than: 0 }
    validates :payment_method, presence: true
    validates :recorded_by_id, presence: true
    validates :payment_lines, presence: true
    validate :payment_lines_sum_matches_total

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        person = Person.find(person_id)
        recorded_by = User.find(recorded_by_id)

        ActiveRecord::Base.transaction do
          # Create payment
          payment = person.payments.create!(
            total_cents: total_cents,
            payment_method: payment_method.to_sym,
            status: :success,
            recorded_by: recorded_by,
            notes: notes
          )

          # Create payment lines
          payment_lines.each do |line_params|
            payment.payment_lines.create!(
              item_type: line_params[:item_type],
              item_id: line_params[:item_id],
              amount_cents: line_params[:amount_cents].to_i,
              description: line_params[:description] || "Paiement #{line_params[:item_type]}"
            )
          end

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "payment.created",
            payment_id: payment.id,
            person_id: person.id,
            total_cents: total_cents,
            payment_method: payment_method,
            recorded_by_id: recorded_by_id,
            lines_count: payment_lines.length
          )

          success(payment: payment, message: "Payment created successfully")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[PaymentCreatorWithLines] Error: #{e.message}"
        failure("Error creating payment: #{e.message}")
      end
    end

    private

    def payment_lines_sum_matches_total
      return if payment_lines.empty?

      lines_sum = payment_lines.sum { |line| line[:amount_cents].to_i }
      if lines_sum != total_cents
        errors.add(:payment_lines, "La somme des lignes (#{lines_sum} cents) ne correspond pas au total (#{total_cents} cents)")
      end
    end

    # success et failure hérités de BaseService
  end
end

