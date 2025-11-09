require "ostruct"

module People
  class PaymentCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :payment, :payment_lines, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :amount_cents, :integer
    attribute :total_cents, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :payment_lines, default: []
    attribute :item_type, :string
    attribute :item_id, :integer
    attribute :description, :string
    attribute :notes, :string
    attribute :status, :string, default: "success"

    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered pending] }
    validate :person_present
    validate :recorded_by_present
    validate :validate_amount_requirements
    validate :validate_payment_lines_sum

    def call
      return failure("Invalid payment data: #{errors.full_messages.join(', ')}") unless valid?

      target_person = resolve_person
      recorded_by = resolve_recorded_by
      normalized_lines = normalize_payment_lines
      total = determine_total(normalized_lines)

      payment = nil

      ActiveRecord::Base.transaction do
        payment = target_person.payments.create!(
          total_cents: total,
          payment_method: payment_method,
          status: status,
          recorded_by: recorded_by,
          notes: notes
        )

        created_lines = if normalized_lines.any?
          create_multiple_lines(payment, normalized_lines)
        else
          [create_single_line(payment)]
        end

        instrument_payment_created(payment, created_lines.length)

        return success(payment: payment, payment_lines: created_lines)
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue => e
      Rails.logger.error("[People::PaymentCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error creating payment: #{e.message}")
    end

    private

    def resolve_person
      return person if person.present?
      raise ActiveRecord::RecordNotFound, "Person not found" if person_id.blank?

      Person.find(person_id)
    end

    def resolve_recorded_by
      return User.find(recorded_by_id) if recorded_by_id.present?

      if Current.respond_to?(:user) && Current.user.present?
        Current.user
      else
        raise ActiveRecord::RecordNotFound, "Recorded_by user not provided"
      end
    end

    def create_single_line(payment)
      line_amount = amount_cents.to_i
      line_item_type = item_type.presence || "Donation"
      line_description = description.presence || default_description_for(line_item_type)

      if donation_line?(line_item_type)
        payment.payment_lines.create!(
          item_type: "Payment",
          item_id: payment.id,
          amount_cents: line_amount,
          description: line_description
        )
      else
        payment.payment_lines.create!(
          item_type: line_item_type,
          item_id: item_id,
          amount_cents: line_amount,
          description: line_description
        )
      end
    end

    def create_multiple_lines(payment, lines)
      lines.map do |line|
        payment.payment_lines.create!(
          item_type: line[:item_type],
          item_id: line[:item_id],
          amount_cents: line[:amount_cents].to_i,
          description: line[:description].presence || default_description_for(line[:item_type])
        )
      end
    end

    def normalize_payment_lines
      Array(payment_lines).map do |line|
        line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
        line.symbolize_keys
      end
    end

    def determine_total(lines)
      if lines.any?
        total_cents.to_i
      else
        amount_cents.to_i
      end
    end

    def default_description_for(item_type)
      base = item_type.to_s.downcase
      if donation_line?(item_type)
        "Donation"
      else
        "Paiement #{base}"
      end
    end

    def donation_line?(item_type)
      item_type.to_s.casecmp("donation").zero?
    end

    def instrument_payment_created(payment, lines_count)
      ActiveSupport::Notifications.instrument(
        "payment.created",
        payment_id: payment.id,
        person_id: payment.person_id,
        total_cents: payment.total_cents,
        payment_method: payment.payment_method,
        recorded_by_id: payment.recorded_by_id,
        lines_count: lines_count
      )
    end

    def success(payment:, payment_lines: [])
      Result.new(success?: true, payment: payment, payment_lines: payment_lines, errors: [], message: "Payment created successfully")
    end

    def failure(message, errors = nil)
      Result.new(success?: false, payment: nil, payment_lines: [], errors: Array(errors || message), message: message)
    end

    def person_present
      return if person.present? || person_id.present?

      errors.add(:person, "must be provided")
    end

    def recorded_by_present
      return if recorded_by_id.present? || (Current.respond_to?(:user) && Current.user.present?)

      errors.add(:recorded_by_id, "must be provided")
    end

    def validate_amount_requirements
      if Array(payment_lines).any?
        if total_cents.blank? || total_cents.to_i <= 0
          errors.add(:total_cents, "must be greater than zero when payment lines are provided")
        end
      else
        if amount_cents.blank? || amount_cents.to_i <= 0
          errors.add(:amount_cents, "must be greater than zero")
        end
        if item_type.blank? && description.blank?
          errors.add(:item_type, "cannot be blank when no payment lines provided")
        end
      end
    end

    def validate_payment_lines_sum
      lines = Array(payment_lines)
      return if lines.empty?

      lines_sum = lines.sum { |line| line[:amount_cents].to_i }
      if total_cents.to_i != lines_sum
        errors.add(:payment_lines, "La somme des lignes (#{lines_sum} cents) ne correspond pas au total (#{total_cents.to_i} cents)")
      end
    end
  end
end
