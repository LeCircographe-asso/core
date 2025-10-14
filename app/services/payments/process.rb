require "ostruct"

module Payments
  class Process
    include ActiveModel::Model
    include ActiveModel::Attributes

    def initialize(payment = nil)
      super()
      @payment = payment
    end

    def payment
      @payment
    end

    def call
      return failure("Payment is required") unless payment
      return failure("Payment is already processed") if payment.success?

      ActiveRecord::Base.transaction do
        process_payment_lines
        update_payment_status
        create_related_objects
        success
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def process_payment_lines
      payment.payment_lines.each do |line|
        case line.item_type
        when "Membership"
          process_membership_payment(line)
        when "SubscriptionPlan"
          process_subscription_plan_payment(line)
        when "MembershipType"
          process_membership_type_payment(line)
        end
      end
    end

    def process_membership_payment(line)
      membership = line.item
      membership.update!(status: :active) if membership.pending?
    end

    def process_subscription_plan_payment(line)
      subscription_plan = line.item
      person = payment.person

      # Vérifier que la personne existe
      return unless person

      # Créer un carnet (BookOfEntry) pour les plans pack
      if subscription_plan.is_pack?
        create_book_of_entry(person, subscription_plan)
      end
    end

    def process_membership_type_payment(line)
      membership_type = line.item
      person = payment.person

      # Vérifier que la personne existe
      return unless person

      # Créer une adhésion
      create_membership(person, membership_type)
    end

    def create_book_of_entry(person, subscription_plan)
      BookOfEntry.create!(
        person: person,
        subscription_plan: subscription_plan,
        sessions_remaining: subscription_plan.sessions_count,
        status: :active
      )
    end

    def create_membership(person, membership_type)
      start_date = Date.current
      end_date = start_date + 1.year

      Membership.create!(
        person: person,
        membership_type: membership_type,
        started_at: start_date,
        ended_at: end_date,
        status: :active,
        first_joined_at: start_date
      )
    end

    def update_payment_status
      payment.update!(status: :success)
    end

    def create_related_objects
      # Cette méthode peut être étendue pour créer d'autres objets liés
      # comme des notifications, des logs d'audit, etc.
    end

    def success
      OpenStruct.new(
        success?: true,
        payment: payment,
        message: "Payment processed successfully"
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [ message ],
        message: message
      )
    end
  end
end
