# frozen_string_literal: true

module People
  class PaymentRecorder
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :payment, :payment_lines, :errors, :message, keyword_init: true)

    attr_accessor :person, :recorded_by

    attribute :person_id, :integer
    attribute :recorded_by_id, :integer
    attribute :total_cents, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :status, :string, default: "success"
    attribute :notes, :string
    attribute :offer_reason, :string
    attribute :payment_lines, default: []

    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :status, presence: true, inclusion: { in: %w[pending success cancel] }
    validate :person_present
    validate :recorded_by_present
    validate :payment_lines_present
    validate :total_matches_lines
    validate :total_allowed_for_payment_method
    validate :offer_reason_required_for_offered

    def call
      return failure("Invalid payment data: #{errors.full_messages.join(', ')}") unless valid?

      target_person = resolve_person
      recorder = resolve_recorded_by
      normalized_lines = normalize_payment_lines

      payment = nil
      created_lines = []

      ActiveRecord::Base.transaction do
        payment = target_person.payments.create!(
          total_cents: total_cents.to_i,
          payment_method: payment_method,
          status: status,
          recorded_by: recorder,
          notes: notes,
          offer_reason: normalized_offer_reason
        )

        created_lines = normalized_lines.map do |line|
          payment.payment_lines.create!(
            item_type: line[:item_type],
            item_id: item_id_for(line, payment),
            amount_cents: line[:amount_cents].to_i,
            description: line[:description]
          )
        end

        instrument_payment_created(payment, created_lines.length)
      end

      success(payment: payment, payment_lines: created_lines)
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::PaymentRecorder] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error creating payment: #{e.message}")
    end

    private

    def resolve_person
      return person if person.present?
      raise ActiveRecord::RecordNotFound, "Person not found" if person_id.blank?

      Person.find(person_id)
    end

    def resolve_recorded_by
      return recorded_by if recorded_by.present?
      return User.find(recorded_by_id) if recorded_by_id.present?

      raise ActiveRecord::RecordNotFound, "Recorded_by user not provided" unless Current.respond_to?(:user) && Current.user.present?

      Current.user
    end

    def normalize_payment_lines
      Array(payment_lines).map do |line|
        line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
        line.symbolize_keys
      end
    end

    def item_id_for(line, payment)
      return payment.id if donation_line?(line[:item_type])

      line[:item_id]
    end

    def donation_line?(item_type)
      item_type.to_s.casecmp("donation").zero?
    end

    def normalized_offer_reason
      return if payment_method != "offered"

      offer_reason.to_s.strip.presence
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

    def person_present
      return if person.present? || person_id.present?

      errors.add(:person, "must be provided")
    end

    def recorded_by_present
      return if recorded_by.present? || recorded_by_id.present? || (Current.respond_to?(:user) && Current.user.present?)

      errors.add(:recorded_by_id, "must be provided")
    end

    def payment_lines_present
      errors.add(:payment_lines, "must include at least one line") if normalize_payment_lines.empty?
    end

    def total_matches_lines
      lines = normalize_payment_lines
      return if lines.empty?

      lines_sum = lines.sum { |line| line[:amount_cents].to_i }
      return if total_cents.to_i == lines_sum

      errors.add(:payment_lines, "La somme des lignes (#{lines_sum} cents) ne correspond pas au total (#{total_cents.to_i} cents)")
    end

    def total_allowed_for_payment_method
      return if total_cents.present? && total_cents.to_i.positive?
      return if payment_method == "offered" && total_cents.to_i >= 0

      errors.add(:total_cents, "must be greater than zero")
    end

    def offer_reason_required_for_offered
      return unless payment_method == "offered"
      return if normalized_offer_reason.present?

      errors.add(:offer_reason, "must be provided for an offered payment")
    end

    def success(payment:, payment_lines:)
      Result.new(success?: true, payment: payment, payment_lines: payment_lines, errors: [], message: "Payment created successfully")
    end

    def failure(message)
      Result.new(success?: false, payment: nil, payment_lines: [], errors: [ message ], message: message)
    end
  end
end
