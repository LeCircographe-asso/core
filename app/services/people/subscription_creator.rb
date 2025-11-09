require "ostruct"

module People
  class SubscriptionCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :book_of_entry, :payment, :errors, :message, keyword_init: true)

    attr_accessor :person

    attribute :person_id, :integer
    attribute :subscription_plan_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :record_attendance, :boolean, default: false
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string

    validates :subscription_plan_id, presence: true
    validates :payment_method, presence: true, inclusion: { in: %w[cash card cheque transfer offered pending] }
    validate :person_present
    validate :recorded_by_present

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      target_person = resolve_person
      subscription_plan = SubscriptionPlan.find(subscription_plan_id)
      recorded_by = resolve_recorded_by

      result = target_person.create_subscription!(
        subscription_plan,
        payment_method: payment_method.to_sym,
        recorded_by: recorded_by,
        record_attendance: record_attendance,
        custom_amount_cents: custom_amount_cents,
        offer_reason: offer_reason
      )

      instrument_subscription_created(target_person, subscription_plan, recorded_by, result[:book_of_entry], result[:payment])

      success(
        book_of_entry: result[:book_of_entry],
        payment: result[:payment],
        message: "Subscription created successfully"
      )
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue => e
      Rails.logger.error("[People::SubscriptionCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error creating subscription: #{e.message}")
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

    def instrument_subscription_created(person, subscription_plan, recorded_by, book_of_entry, payment)
      ActiveSupport::Notifications.instrument(
        "subscription.created",
        person_id: person.id,
        book_of_entry_id: book_of_entry.id,
        subscription_plan: subscription_plan.name,
        payment_method: payment_method,
        recorded_by_id: recorded_by.id,
        amount_cents: payment.total_cents
      )
    end

    def success(book_of_entry:, payment:, message:)
      Result.new(success?: true, book_of_entry: book_of_entry, payment: payment, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, book_of_entry: nil, payment: nil, errors: Array(errors || message), message: message)
    end

    def person_present
      return if person.present? || person_id.present?

      errors.add(:person, "must be provided")
    end

    def recorded_by_present
      return if recorded_by_id.present? || (Current.respond_to?(:user) && Current.user.present?)

      errors.add(:recorded_by_id, "must be provided")
    end
  end
end
