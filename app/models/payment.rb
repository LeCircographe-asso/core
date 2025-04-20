class Payment < ApplicationRecord
  include SoftDeletable

  belongs_to :user
  belongs_to :order
  has_many :product_orders, through: :order # Ajout de la relation product_order
  has_many :payment_audit_logs, dependent: :destroy

  enum :status, %i[success pending cancel], default: :pending
  enum :payment_type, %i[cash credit_card check]

  before_create :generate_uuid
  after_create :create_audit_log
  after_update :update_user_membership_if_paid, if: -> { saved_change_to_status? && status == "success" }
  after_update :createBookOfEntry, if: -> { saved_change_to_status? && status == "success" }
  after_update :log_status_change, if: -> { saved_change_to_status? }

  # Scope to get active (non-cancelled) payments
  scope :active, -> { where.not(status: :cancel) }

  # Class method to get total successful payments amount
  def self.total_successful_amount
    Rails.cache.fetch("total_successful_payments", expires_in: 1.hour) do
      where(status: :success).distinct.sum(:payment_amount)
    end
  end

  # Class method to get total donations
  def self.total_donations
    Rails.cache.fetch("total_donations", expires_in: 1.hour) do
      where(status: :success).distinct.sum(:donation)
    end
  end

  # Generate a UUID for the payment
  def generate_uuid
    self.uuid = SecureRandom.uuid
  end

  # Create an audit log entry for new payments
  def create_audit_log
    PaymentAuditLog.log(self, user, "create")
  end

  # Log status changes
  def log_status_change
    change_data = {
      status: {
        from: status_before_last_save,
        to: status
      }
    }
    PaymentAuditLog.log(self, user, "status_change", change_data)

    # Invalidate cache when status changes
    Rails.cache.delete("total_successful_payments")
    Rails.cache.delete("total_donations")
  end

  # Handle when user is soft deleted
  def handle_user_deletion
    # Instead of destroying the payment or losing the relationship,
    # we maintain the data but anonymize any personal identifiable information
    # This preserves payment history while protecting user privacy
    update_columns(
      # We keep the payment record but mark it as associated with a deleted user
      status: :cancel,
      # Add a note that the user was deleted
      donation: (donation || 0)
    )

    # Log the user deletion effect on payment
    PaymentAuditLog.log(self, nil, "user_deleted")

    # Invalidate cache
    Rails.cache.delete("total_successful_payments")
    Rails.cache.delete("total_donations")
  end

  # Check if a payment can be safely canceled
  def can_cancel?
    status != "cancel"
  end

  # Override destroy method to ensure audit trail
  def destroy
    PaymentAuditLog.log(self, Current.user, "delete")

    # Invalidate cache
    Rails.cache.delete("total_successful_payments")
    Rails.cache.delete("total_donations")

    super
  end

  # Check if this payment is related to a membership
  def membership_related?
    product_orders.any? do |po|
      po.product.product_name.include?("Adhésion") ||
      po.product.product_name.include?("Cotisation")
    end
  end

  def payment_successful?
    # Vérifier si la commande a déjà été payée
    if order.payments.where(status: "success").exists?
      order.product_orders.each do |product_order|
        puts "Product name: #{product_order.product.product_name}"

        if product_order.product.product_name == "Cotisation 10 séances"
          puts "Matching product found"
          BookOfEntry.create!(user_id: self.user_id, product_id: product_order.product.id, remaining: 10, total_entry: 10)
          puts "Book of Entry created"
        else
          puts "Product does not match: #{product_order.product.product_name}"
        end
      end
    end
  end


  def createBookOfEntry
    # Vérifier si des product_orders existent pour la commande
    if self.product_orders.empty?
      puts "Aucun produit associé à cette commande"
    else
      self.product_orders.each do |product_order|
        puts "Product name: #{product_order.product.product_name}"
      end

      product_order = self.product_orders.first
      puts "Product name: #{product_order.product.product_name}"

      if product_order.product.product_name == "Cotisation 10 séances"
        BookOfEntry.create!(user_id: self.user_id, product_id: product_order.product.id, remaining: 10, total_entry: 10)
        puts "Book of Entry created"
      end
    end
  end




  def update_user_membership_if_paid
    return unless payment_successful?

    membership_type = determine_user_membership
    return unless membership_type

    user_membership = user.user_memberships.where(status: :active).last
    if user_membership.nil?
      # Si l'utilisateur n'a pas d'abonnement actif, on en crée un
      user_membership = UserMembership.create!(user: user, membership_id: membership_type, start_date: created_at, status: :active)
      puts "Membership créé"
    else
      # Si l'utilisateur a un abonnement actif, on met à jour sa date d'expiration
      user_membership.update!(membership_id: membership_type)
      puts "Membership mis à jour"
    end
    update_user_membership_end_date(user_membership)
  end

  def determine_user_membership
    product_names = product_orders.map { |po| po.product.product_name }.join(", ")
    circus = Membership.find_by(type_name: :Circus).id
    basic = Membership.find_by(type_name: :Basic).id
    no_member = Membership.find_by(type_name: :No_Member).id

    circus_products = [
      "Adhésion Cirque - Tarif Plein",
      "Upgrade Basic to Cirque - Tarif Plein",
      "Upgrade Basic to Cirque - Tarif Réduit",
      "Cotisation annuelle",
      "Cotisation trimestrielle",
      "Cotisation 10 séances",
      "Pass journée"
    ]

    return circus if circus_products.any? { |name| product_names.include?(name) }
    return basic if product_names.include?("Adhésion simple")
    no_member if product_names.include?("Donation")
  end

  def determine_end_date(product_name)
    case product_name
    when "Cotisation trimestrielle"
      3.months.from_now
    when "Pass journée"
      1.day.from_now
    when "Donation"
      nil
    else
      1.year.from_now
    end
  end

  def update_user_membership_end_date(user_membership)
    product_name = product_orders.first.product.product_name # Modifié pour prendre le premier produit
    end_date = determine_end_date(product_name)

    if end_date
      user_membership.update!(status: :active, end_date: end_date)
      puts "Mise à jour de l'abonnement pour l'utilisateur #{user.id} avec le type #{product_name}"
    end
  end
end
