class BookOfEntry < ApplicationRecord
  include Statusable
  include Dateable

  # Relations selon le domain_model_circographe.md
  belongs_to :person
  belongs_to :subscription_plan
  # Validations
  validates :sessions_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :has_session_limit?
  validates :status, presence: true
  validates :purchased_at, presence: true
  validates :expires_at, presence: true, unless: :is_pack10?

  # Validation personnalisée pour les séances
  validate :sessions_remaining_validation

  # Enum pour les statuts selon le domain_model_circographe.md
  enum :status, {
    inactive: 0,
    active: 1,
    expired: 2,
    consumed: 3,
    suspended: 4
  }

  before_create :set_initial_values

  # Méthodes
  def can_use?
    # Un carnet peut être utilisé s'il est actif et a des séances restantes
    return false unless active?

    if has_session_limit?
      return false unless sessions_remaining.present? && sessions_remaining > 0
    end

    # Pour les packs, vérifier qu'il n'est pas expiré (sauf si c'est un pack10)
    return false if expired? && !is_pack10?

    # Vérifier que la personne a une adhésion Circus active
    return false unless person.current_membership&.membership_type&.circus?

    true
  end

  def use_session!
    # Décrémenter une séance et mettre à jour le statut
    return false unless can_use?

    if has_session_limit?
      self.sessions_remaining -= 1

      if sessions_remaining == 0
        self.status = :consumed
      end
    end

    save!
  end

  def refund_session!
    return true unless has_session_limit?

    max_sessions = subscription_plan.sessions_count
    max_sessions ||= is_pack10? ? 10 : 1

    self.sessions_remaining ||= 0
    self.sessions_remaining = [ sessions_remaining + 1, max_sessions ].min
    self.status = :active if sessions_remaining.positive?
    save!
  end

  def expired?
    # Les packs10 ne expirent jamais et se réactivent avec une nouvelle adhésion
    return false if is_pack10?

    # Pour les journées, vérifier si on est après la fin de journée
    if subscription_plan.duration == "day"
      return Time.current > expires_at.end_of_day
    end

    Date.current > expires_at
  end

  def is_pack10?
    subscription_plan.duration == "pack10"
  end

  def has_session_limit?
    # Les packs10 et les journées ont une limite de séances
    # Les abonnements (trimester, annual) n'en ont pas (accès rapide à la présence)
    is_pack10? || subscription_plan.duration == "day"
  end

  def remaining_entries
    sessions_remaining
  end

  # Scopes optimisés pour les requêtes d'expiration
  scope :expired_by_date, -> { where("expires_at < ?", Date.current) }
  scope :not_expired_by_date, -> { where("expires_at IS NULL OR expires_at > ?", Date.current) }
  scope :with_expiration, -> { where.not(expires_at: nil) }
  scope :without_expiration, -> { where(expires_at: nil) }

  # Scopes de statut
  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }
  scope :consumed, -> { where(status: :consumed) }
  scope :suspended, -> { where(status: :suspended) }

  # Scope utilisable : actif, pas expiré par date, et avec séances restantes (si applicable)
  scope :usable, -> {
    active
      .where("expires_at IS NULL OR expires_at > ?", Date.current)
      .where("sessions_remaining IS NULL OR sessions_remaining > 0")
  }

  # Méthodes de classe
  def self.reactivate_suspended_packs_for_person(person)
    return unless person.can_buy_subscription_plans?

    # Si aucun plan actif (Trimestre/Année), réactiver Pack10 suspendus
    active_plans = person.book_of_entries.active.joins(:subscription_plan).where.not(subscription_plans: { duration: "pack10" })

    if active_plans.empty?
      person.book_of_entries.suspended.joins(:subscription_plan).where(subscription_plans: { duration: "pack10" }).each(&:reactivate!)
    end
  end

  # Instance methods
  def suspend!(reason:)
    update!(status: :suspended, suspended_at: Time.current, suspended_reason: reason)
  end

  def reactivate!
    update!(status: :active, suspended_at: nil, suspended_reason: nil) if suspended?
  end

  def suspended?
    status == "suspended"
  end

  private

  def sessions_remaining_validation
    # Pour les abonnements illimités (trimester, annual), sessions_remaining doit être nil
    if subscription_plan&.duration.in?([ "trimester", "annual" ])
      if sessions_remaining.present?
        errors.add(:sessions_remaining, "doit être vide pour les abonnements illimités")
      end
    # Pour les packs et journées, sessions_remaining doit être présent et positif
    elsif has_session_limit?
      if sessions_remaining.blank? || sessions_remaining < 0
        errors.add(:sessions_remaining, "doit être présent et positif pour les packs et journées")
      end
    end
  end

  def set_initial_values
    # Valeurs par défaut si pas définies
    self.purchased_at ||= Time.current
    self.status ||= :active
    # sessions_remaining is NOT set by default - validation will set it based on duration
    # For unlimited subscriptions (trimester/annual), it MUST be nil
    # For limited subscriptions (pack10/day), it MUST be set explicitly
  end
end
