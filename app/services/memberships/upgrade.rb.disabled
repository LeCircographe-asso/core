require "ostruct"

module Memberships
  class Upgrade
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person_id, :integer
    attribute :new_membership_type_id, :integer
    attribute :started_at, :date
    attribute :payment_method, :string

    validates :person_id, presence: true
    validates :new_membership_type_id, presence: true

    def initialize(attributes = {})
      super
      self.started_at ||= Date.current
      self.payment_method ||= "cash"
    end

    def call
      return failure("Person not found") unless person
      return failure("New membership type not found") unless new_membership_type
      return failure("No current membership to upgrade") unless current_membership
      return failure("Cannot upgrade to this membership type") unless can_upgrade?

      ActiveRecord::Base.transaction do
        calculate_price_difference
        create_upgrade_payment if price_difference > 0
        perform_upgrade
        success
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def person
      @person ||= Person.find_by(id: person_id)
    end

    def new_membership_type
      @new_membership_type ||= MembershipType.find_by(id: new_membership_type_id)
    end

    def current_membership
      @current_membership ||= person&.current_membership
    end

    def can_upgrade?
      current_membership&.can_upgrade_to?(new_membership_type)
    end

    def calculate_price_difference
      current_price = current_membership.membership_type.price_cents
      new_price = new_membership_type.price_cents
      @price_difference = [ new_price - current_price, 0 ].max
    end

    def price_difference
      @price_difference ||= 0
    end

    def create_upgrade_payment
      payment = Payment.create!(
        person: person,
        recorded_by: User.first, # Fallback si Current.user n'est pas disponible
        total_cents: price_difference,
        payment_method: payment_method,
        notes: "Upgrade from #{current_membership.membership_type.name} to #{new_membership_type.name}"
      )

      # Créer une ligne de paiement pour la différence
      PaymentLine.create!(
        payment: payment,
        item: new_membership_type,
        amount_cents: price_difference,
        description: "Upgrade membership"
      )

      # Traiter le paiement
      Payments::Process.new(payment).call
    end

    def perform_upgrade
      current_membership.upgrade_to!(new_membership_type, started_at)
    end

    def success
      OpenStruct.new(
        success?: true,
        new_membership: person.current_membership,
        message: "Membership upgraded successfully to #{new_membership_type.name}"
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
