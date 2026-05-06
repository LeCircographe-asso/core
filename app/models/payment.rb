# frozen_string_literal: true

class Payment < ApplicationRecord
  include Priceable
  include Humanizable
  include Statusable
  include Dateable

  attr_accessor :allow_hard_delete

  # Relations — voir docs/domain_model.md et docs/payments.md.
  belongs_to :person
  belongs_to :recorded_by, class_name: "User"
  has_many :payment_lines, dependent: :destroy
  has_many :payment_audit_logs, dependent: :destroy

  enum :status, { success: 0, pending: 1, cancel: 2 }, default: :pending
  enum :payment_method, { cash: 0, card: 1, cheque: 2, transfer: 3, offered: 4 }, default: :cash

  validates :offer_reason, presence: true, if: :is_offered?

  before_create :generate_uuid
  after_create :create_audit_log
  # Callbacks legacy supprimés : la création/mise à jour cascade passe désormais par les services People::*.
  after_update :log_status_change, if: -> { saved_change_to_status? }
  after_update :invalidate_totals_cache, if: -> { saved_change_to_total_cents? }
  before_destroy :prevent_hard_delete, unless: :allow_hard_delete?
  before_destroy :log_hard_delete, if: :allow_hard_delete?
  before_destroy :invalidate_totals_cache

  # Scope to get active (non-cancelled) payments
  scope :active, -> { where.not(status: :cancel) }

  # Date scopes (using created_at via Dateable)
  scope :today, -> { where(created_at: Date.current.beginning_of_day...Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: Date.current.beginning_of_week.beginning_of_day..Date.current.end_of_week.end_of_day) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month.beginning_of_day..Date.current.end_of_month.end_of_day) }

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
    elsif payment_lines.contributions.any? || payment_lines.contribution_formulas.any?
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
    payment_lines.joins(<<~SQL.squish)
      LEFT JOIN contribution_formulas direct_formulas
        ON payment_lines.item_type = 'ContributionFormula'
       AND payment_lines.item_id = direct_formulas.id
      LEFT JOIN contributions
        ON payment_lines.item_type = 'Contribution'
       AND payment_lines.item_id = contributions.id
      LEFT JOIN contribution_formulas contribution_formulas
        ON contributions.contribution_formula_id = contribution_formulas.id
    SQL
                 .where(
                   "direct_formulas.duration = ? OR contribution_formulas.duration = ?",
                   ContributionFormula.durations[:pack10],
                   ContributionFormula.durations[:pack10]
                 )
                 .exists?
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
    # Intentional single-row bypass: we do not want status callbacks here.
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(
      # We keep the payment record but mark it as associated with a deleted user
      status: :cancel,
      # Add a note that the user was deleted
      notes: "User deleted - payment cancelled"
    )
    # rubocop:enable Rails/SkipsModelValidations

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

  # Intention explicite requise pour les suppressions physiques résiduelles.
  def hard_delete!(actor: recorded_by)
    self.allow_hard_delete = true
    @hard_delete_actor = actor || recorded_by
    destroy!
  ensure
    self.allow_hard_delete = false
    remove_instance_variable(:@hard_delete_actor) if instance_variable_defined?(:@hard_delete_actor)
  end

  # Anonymization for GDPR compliance
  def anonymize!
    with_lock do
      return if anonymized_at.present?

      # payments.person_id is NOT NULL: anonymization is a traceability mark,
      # not a destructive unlink from the owning Person.
      update!(
        original_person_identifier: "ANON_#{Digest::SHA256.hexdigest("#{person_id}_#{id}_#{created_at}")}",
        anonymized_at: Time.current
      )
    end
  end

  scope :anonymized, -> { where.not(anonymized_at: nil) }

  private

  def allow_hard_delete?
    ActiveModel::Type::Boolean.new.cast(allow_hard_delete)
  end

  def prevent_hard_delete
    errors.add(:base, "Hard delete is forbidden; use People::PaymentCanceller")
    throw(:abort)
  end

  def log_hard_delete
    PaymentAuditLog.log(self, @hard_delete_actor || recorded_by, "delete")
  end
end
