require "ostruct"

module People
  class MembershipCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :person
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    validates :person, presence: true
    validates :membership_type_id, presence: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }
    validates :recorded_by_id, presence: true

    def call
      return failure("Invalid data") unless valid?

      ActiveRecord::Base.transaction do
        # Vérifier si la personne a déjà une adhésion active
        if person_has_active_membership?
          return success_with_existing_membership
        end

        membership = create_membership
        payment = create_payment(membership)
        create_payment_line(payment, membership)
        process_payment(payment)

        success(membership, payment)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def person_has_active_membership?
      person.memberships.active.current.exists?
    end

    def success_with_existing_membership
      existing_membership = person.memberships.active.current.first
      OpenStruct.new(
        success?: true,
        membership: existing_membership,
        payment: nil,
        message: "Person already has active membership: #{existing_membership.membership_type.name}",
        already_existed: true
      )
    end

    def create_membership
      person.memberships.create!(
        membership_type_id: membership_type_id,
        started_at: Time.current,
        ended_at: 1.year.from_now,
        status: "active",
        first_joined_at: Time.current
      )
    end

    def create_payment(membership)
      membership_type = MembershipType.find(membership_type_id)
      admin_user = User.find(recorded_by_id)
      
      Payment.create!(
        person: person,
        recorded_by: admin_user,
        total_cents: membership_type.price_cents,
        payment_method: payment_method,
        status: "success",
        notes: "Paiement pour adhésion #{membership_type.name}"
      )
    end

    def create_payment_line(payment, membership)
      membership_type = MembershipType.find(membership_type_id)
      
      PaymentLine.create!(
        payment: payment,
        item: membership,
        amount_cents: membership_type.price_cents,
        description: "Adhésion #{membership_type.name}"
      )
    end

    def process_payment(payment)
      Payments::Process.new(payment).call
    end

    def success(membership, payment)
      OpenStruct.new(
        success?: true,
        membership: membership,
        payment: payment,
        message: "Membership created successfully: #{membership.membership_type.name}",
        already_existed: false
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [message],
        message: message
      )
    end
  end
end
