class Payment < ApplicationRecord
  include Priceable
  include Humanizable
  include Statusable
  include Dateable

  # Relations — voir docs/domain_model.md et docs/payments.md.
  belongs_to :person
  belongs_to :recorded_by, class_name: "User"
  has_many :payment_lines, dependent: :destroy
  has_many :payment_audit_logs, dependent: :destroy

  enum :status, %i[success pending cancel], default: :pending
  enum :payment_method, %i[cash card cheque transfer offered], default: :cash

  before_create :generate_uuid
  after_create :create_audit_log
  # Callbacks legacy supprimés : la création/mise à jour cascade passe désormais par les services People::*.
  after_update :log_status_change, if: -> { saved_change_to_status? }
  after_update :invalidate_totals_cache, if: -> { saved_change_to_total_cents? }

  # Scope to get active (non-cancelled) payments
  scope :active, -> { where.not(status: :cancel) }

  # Date scopes (using created_at via Dateable)
  scope :today, -> { where("created_at >= ? AND created_at < ?", Date.current.beginning_of_day, Date.current.end_of_day) }
  scope :this_week, -> { where("created_at >= ? AND created_at <= ?", Date.current.beginning_of_week.beginning_of_day, Date.current.end_of_week.end_of_day) }
  scope :this_month, -> { where("created_at >= ? AND created_at <= ?", Date.current.beginning_of_month.beginning_of_day, Date.current.end_of_month.end_of_day) }

  # Class method to get total successful payments amount
  def self.total_successful_amount
    Rails.cache.fetch("total_successful_payments", expires_in: 1.hour) do
      where(status: :success).sum(:total_cents)
    end
  end

  # Class method to get total donations
  def self.total_donations
    Rails.cache.fetch("total_donations", expires_in: 1.hour) do
      joins(:payment_lines)
        .where(status: :success)
        .where(payment_lines: { item_type: "Donation" })
        .sum("payment_lines.amount_cents")
    end
  end

  # Méthodes utilitaires de présentation — voir docs/payments.md.
  def payment_type
    # Déterminer le type de paiement basé sur les payment_lines
    if payment_lines.memberships.any?
      "Adhésion"
    elsif payment_lines.subscription_plans.any?
      "Cotisation"
    elsif payment_lines.any?
      # Utiliser la description de la première ligne
      payment_lines.first.item_description
    else
      "Autre"
    end
  end

  # Méthodes pour le système d'encaissement
  # (total_euros et payment_method_humanized maintenant dans les modules)

  def is_offered?
    payment_method == "offered"
  end

  def is_paid?
    status == "success"
  end

  def can_be_cancelled?
    status != "cancel" && created_at > 24.hours.ago
  end

  def membership_related?
    # Vérifier si le paiement contient des adhésions
    payment_lines.joins("JOIN memberships ON payment_lines.item_type = 'Membership' AND payment_lines.item_id = memberships.id").exists?
  end

  def carnet_related?
    # Vérifier si le paiement contient une cotisation Pack 10 (ContributionFormula de type pack — code actuel : SubscriptionPlan).
    payment_lines.joins("JOIN subscription_plans ON payment_lines.item_type = 'SubscriptionPlan' AND payment_lines.item_id = subscription_plans.id")
                 .where("subscription_plans.duration = ?", SubscriptionPlan.durations[:pack10]).exists?
  end

  # Generate a UUID for the payment
  def generate_uuid
    self.uuid = SecureRandom.uuid
  end

  # Create an audit log entry for new payments
  def create_audit_log
    PaymentAuditLog.log(self, recorded_by, "create")
  end

  # Log status changes
  def log_status_change
    return unless saved_change_to_status

    change_data = {
      status: {
        from: saved_change_to_status.first,
        to: status
      }
    }
    PaymentAuditLog.log(self, recorded_by, "status_change", change_data)

    # Invalidate cache when status changes
    Rails.cache.delete("total_successful_payments")
    Rails.cache.delete("total_donations")
  end

  # Invalidate totals cache when payment amount changes
  def invalidate_totals_cache
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
      notes: "User deleted - payment cancelled"
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
    PaymentAuditLog.log(self, recorded_by, "delete")

    # Invalidate cache
    Rails.cache.delete("total_successful_payments")
    Rails.cache.delete("total_donations")

    super
  end

  # Anonymization for GDPR compliance
  def anonymize!
    return if anonymized_at.present?

    self.original_person_identifier = "ANON_#{Digest::SHA256.hexdigest("#{person_id}_#{id}_#{created_at}")}"
    self.person_id = nil
    self.anonymized_at = Time.current
    save!
  end

  scope :anonymized, -> { where.not(anonymized_at: nil) }
end
