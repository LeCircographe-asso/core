require "ostruct"

module People
  class SubscriptionUpgrader
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :old_book, :new_book, :payment, :credit_applied, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :from_book_id, :integer
    attribute :to_plan_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    validates :from_book_id, presence: true
    validates :to_plan_id, presence: true
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :recorded_by_id, presence: true
    validate :person_identifier_present

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      target_person = resolve_person
      recorded_by = resolve_user

      result = target_person.upgrade_subscription!(
        from_book_id: from_book_id,
        to_plan_id: to_plan_id,
        payment_method: payment_method.to_sym,
        recorded_by: recorded_by
      )

      instrument_upgrade(target_person, recorded_by, result)

      success(
        old_book: result[:old_book],
        new_book: result[:new_book],
        payment: result[:payment],
        credit_applied: result[:credit_applied] || 0,
        message: "Subscription upgraded successfully"
      )
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue => e
      Rails.logger.error("[People::SubscriptionUpgrader] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error upgrading subscription: #{e.message}")
    end

    private

    def resolve_person
      return person if person.present?

      Person.find(person_id)
    end

    def resolve_user
      User.find(recorded_by_id)
    end

    def instrument_upgrade(person, recorded_by, result)
      ActiveSupport::Notifications.instrument(
        "subscription.upgraded",
        person_id: person.id,
        from_book_id: from_book_id,
        to_plan_id: to_plan_id,
        payment_method: payment_method,
        recorded_by_id: recorded_by.id,
        amount_cents: result[:payment]&.total_cents || 0,
        credit_applied: result[:credit_applied] || 0
      )
    end

    def person_identifier_present
      errors.add(:person_id, "must be provided") if person.blank? && person_id.blank?
    end

    def success(old_book:, new_book:, payment:, credit_applied:, message:)
      Result.new(success?: true, old_book: old_book, new_book: new_book, payment: payment, credit_applied: credit_applied, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, old_book: nil, new_book: nil, payment: nil, credit_applied: 0, errors: Array(errors || message), message: message)
    end
  end
end
