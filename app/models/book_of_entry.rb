class BookOfEntry < ApplicationRecord
  # Relations selon le domain_model_circographe.md
  belongs_to :person
  belongs_to :subscription_plan

  # Anciennes relations (à supprimer progressivement)
  belongs_to :product, optional: true
  belongs_to :user, optional: true

  # Validations
  validates :sessions_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :has_session_limit?
  validates :status, presence: true
  validates :purchased_at, presence: true
  validates :expires_at, presence: true, unless: :is_pack10?

  # Enum pour les statuts selon le domain_model_circographe.md
  enum :status, {
    inactive: 0,
    active: 1,
    expired: 2,
    consumed: 3
  }

  # Callbacks
  before_create :set_initial_values
  after_create :bookOfEntryValidation

  # Méthodes
  def can_use?
    # Un carnet peut être utilisé s'il est actif et a des séances restantes
    return false unless active? && sessions_remaining > 0

    # Pour les packs, vérifier qu'il n'est pas expiré (sauf si c'est un pack10)
    return false if expired? && !is_pack10?

    # Vérifier que la personne a une adhésion Circus active
    return false unless person.current_membership&.membership_type&.circus?

    true
  end

  def use_session!
    # Décrémenter une séance et mettre à jour le statut
    return false unless can_use?

    self.sessions_remaining -= 1

    if sessions_remaining == 0
      self.status = :consumed
    end

    save!
  end

  def expired?
    # Les packs10 ne expirent jamais
    return false if is_pack10?

    Date.current > expires_at
  end

  def is_pack10?
    subscription_plan.duration == "pack10"
  end

  def has_session_limit?
    # Les packs10 et les journées ont une limite de séances
    # Les abonnements (trimester, annual) n'en ont pas
    is_pack10? || subscription_plan.duration == "day"
  end

  def remaining_entries
    sessions_remaining
  end

  # Scopes optimisés pour les requêtes d'expiration
  scope :expired, -> { where("expires_at < ?", Date.current) }
  scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Date.current) }
  scope :with_expiration, -> { where.not(expires_at: nil) }
  scope :without_expiration, -> { where(expires_at: nil) }
  scope :usable, -> { active.not_expired.where("sessions_remaining > 0") }

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }
  scope :consumed, -> { where(status: :consumed) }
  scope :usable, -> { where(status: :active).where("sessions_remaining > 0") }
  scope :expired_by_date, -> { where("expires_at < ?", Date.current) }

  # Méthodes de classe

  private

  def set_initial_values
    # Valeurs par défaut si pas définies
    self.purchased_at ||= Time.current
    self.status ||= :active
    self.sessions_remaining ||= 0
  end

  def bookOfEntryValidation
    erreurs = []

    if person_id.blank?
      erreurs << "La personne est obligatoire"
    end

    if subscription_plan_id.blank?
      erreurs << "Le plan d'abonnement est obligatoire"
    end

    if sessions_remaining.blank? || sessions_remaining < 0
      erreurs << "Le nombre de séances restantes doit être positif"
    end

    if purchased_at.blank?
      erreurs << "La date d'achat est obligatoire"
    end

    if expires_at.blank?
      erreurs << "La date d'expiration est obligatoire"
    end

    if expires_at && purchased_at && expires_at <= purchased_at
      erreurs << "La date d'expiration doit être après la date d'achat"
    end
  end
end
