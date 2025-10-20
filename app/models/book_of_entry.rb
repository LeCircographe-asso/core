class BookOfEntry < ApplicationRecord
  # Relations selon le domain_model_circographe.md
  belongs_to :person
  belongs_to :subscription_plan
  
  # Anciennes relations (à supprimer progressivement)
  belongs_to :product, optional: true
  belongs_to :user, optional: true
  
  # Validations
  validates :sessions_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :purchased_at, presence: true
  validates :expires_at, presence: true
  
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
    active? && sessions_remaining > 0 && !expired?
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
    Date.current > expires_at
  end

  def remaining_entries
    sessions_remaining
  end
  
  def expire!
    # Marquer le carnet comme expiré
    update!(status: :expired) if active?
  end
  
  # Scopes
  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }
  scope :consumed, -> { where(status: :consumed) }
  scope :usable, -> { where(status: :active).where('sessions_remaining > 0') }
  scope :expired_by_date, -> { where('expires_at < ?', Date.current) }
  
  # Méthodes de classe
  def self.create_from_subscription_plan!(person, subscription_plan, purchased_at = Time.current)
    # Créer un carnet à partir d'un plan d'abonnement pack10
    raise "Subscription plan must be a pack" unless subscription_plan.is_pack?
    
    expires_at = purchased_at + (subscription_plan.validity_days || 365).days
    
    create!(
      person: person,
      subscription_plan: subscription_plan,
      sessions_remaining: subscription_plan.sessions_count,
      status: :active,
      purchased_at: purchased_at,
      expires_at: expires_at
    )
  end
  
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
