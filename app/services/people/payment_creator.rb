# frozen_string_literal: true

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
    attribute :offer_reason, :string
    attribute :status, :string, default: "success"

    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered pending] }
    validate :person_present
    validate :recorded_by_present
    validate :validate_amount_requirements
    validate :validate_payment_lines_sum

    def call
      return failure("Invalid payment data: #{errors.full_messages.join(', ')}") unless valid?

      normalized_lines = normalize_payment_lines
      total = determine_total(normalized_lines)

      lines = normalized_lines.any? ? normalized_lines : [ single_line_attributes ]
      People::PaymentRecorder.new(
        person: person,
        person_id: person_id,
        recorded_by_id: recorded_by_id,
        total_cents: total,
        payment_method: payment_method,
        status: status,
        notes: notes,
        offer_reason: offer_reason,
        payment_lines: lines
      ).call
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::PaymentCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error creating payment: #{e.message}")
    end

    private

    def single_line_attributes
      line_item_type = item_type.presence || "Donation"
      line_description = description.presence || default_description_for(line_item_type)

      {
        item_type: line_item_type,
        item_id: item_id,
        amount_cents: amount_cents.to_i,
        description: line_description
      }
    end

    def normalize_payment_lines
      Array(payment_lines).map do |line|
        line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
        line.symbolize_keys.tap do |attrs|
          attrs[:description] = attrs[:description].presence || default_description_for(attrs[:item_type])
        end
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
        return if payment_method == "offered" && total_cents.to_i >= 0

        errors.add(:total_cents, "must be greater than zero when payment lines are provided") if total_cents.blank? || total_cents.to_i <= 0
      else
        unless payment_method == "offered" && amount_cents.to_i >= 0
          errors.add(:amount_cents, "must be greater than zero") if amount_cents.blank? || amount_cents.to_i <= 0
        end
        errors.add(:item_type, "cannot be blank when no payment lines provided") if item_type.blank? && description.blank?
      end
    end

    def validate_payment_lines_sum
      lines = normalize_payment_lines
      return if lines.empty?

      lines_sum = lines.sum { |line| line[:amount_cents].to_i }
      return unless total_cents.to_i != lines_sum

      errors.add(:payment_lines, "La somme des lignes (#{lines_sum} cents) ne correspond pas au total (#{total_cents.to_i} cents)")
    end
  end
end
