class Person < ApplicationRecord
  # Relations
  has_one :user, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :book_of_entries, dependent: :destroy
  has_many :member_number_histories, dependent: :destroy

  # Attribut pour skip validation dans certains cas (seeds, migrations)
  attr_accessor :skip_membership_validation

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :member_number, uniqueness: true, allow_blank: true
  
  # Validation conditionnelle : email obligatoire si newsletter activée
  validates :email, presence: true, if: :newsletter_subscribed?
  
  # Validation d'adhésion obligatoire (sauf cas spéciaux)
  validate :must_have_active_membership, unless: :skip_membership_validation
  
  # Normalisation des données
  before_validation :normalize_email

  # Méthodes
  def full_name
    "#{first_name} #{last_name}"
  end

  # Affiche le numéro d'adhérent de manière lisible
  def formatted_member_number
    return "Non assigné" unless member_number.present?
    
    parsed = MemberManagementService.parse_member_number(member_number)
    return member_number unless parsed
    
    "#{parsed[:year]} - #{parsed[:type]} - ##{parsed[:number]}"
  end

  # Retourne les détails du numéro d'adhérent
  def member_number_details
    return nil unless member_number.present?
    MemberManagementService.parse_member_number(member_number)
  end

  # Retourne l'historique des numéros d'adhérent
  def member_number_history
    member_number_histories.order(:assigned_at)
  end

  # Retourne le numéro d'adhérent actuel (depuis l'historique)
  def current_member_number_history
    member_number_histories.current.first
  end

  # Retourne tous les numéros d'adhérent précédents
  def previous_member_numbers
    member_number_histories.historical.order(:assigned_at)
  end

  # Change le numéro d'adhérent (avec historique)
  def change_member_number(new_membership_type, notes = nil)
    return false if member_number.blank?
    
    # Normaliser le type d'adhésion
    normalized_type = case new_membership_type.to_s.upcase
                     when 'CIRQUE', 'C'
                       'Cirque'
                     when 'BASIQUE', 'U', 'BASIC'
                       'Basique'
                     else
                       'Basique' # Par défaut
                     end
    
    # Marquer l'ancien numéro comme remplacé
    current_history = current_member_number_history
    current_history&.mark_as_replaced!
    
    # Générer le nouveau numéro
    new_number = MemberManagementService.generate_member_number(new_membership_type)
    
    # Créer l'historique
    member_number_histories.create!(
      member_number: new_number,
      membership_type: normalized_type,
      year: Date.current.year,
      notes: notes,
      assigned_at: Time.current
    )
    
    # Mettre à jour le numéro actuel
    self.skip_membership_validation = true
    update!(member_number: new_number)
    
    new_number
  end

  def has_user_account?
    user.present?
  end

  def current_membership
    memberships.active.current.first
  end

  def has_active_membership?
    current_membership.present?
  end

  def can_buy_subscription_plans?
    # Seuls les membres Circus peuvent acheter des plans d'abonnement
    current_membership&.membership_type&.circus?
  end

  def minor?
    is_minor
  end

  def adult?
    !is_minor
  end

  # Scopes
  scope :with_user_account, -> { joins(:user) }
  scope :without_user_account, -> { left_joins(:user).where(users: { id: nil }) }
  scope :by_name, ->(query) { where("first_name LIKE ? OR last_name LIKE ?",
                                        "%#{query}%", "%#{query}%") }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :with_phone, -> { where.not(phone: [ nil, "" ]) }
  scope :minors, -> { where(is_minor: true) }
  scope :adults, -> { where(is_minor: false) }
  
  # Scopes pour le tableau de bord admin
  scope :with_active_membership, -> { joins(:memberships).where(memberships: { status: :active }) }
  
  # Scope pour ne montrer que les Person "principales" (éviter les doublons)
  scope :main_people, -> {
    # Person avec User lié OU Person unique (pas de doublon de nom)
    where(
      id: Person.joins(:user).select(:id)
    ).or(
      where(
        id: Person.group(:first_name, :last_name)
                 .having('COUNT(*) = 1')
                 .select(:id)
      )
    )
  }

  scope :with_expiring_membership, -> { 
    joins(:memberships)
      .where(memberships: { status: :active })
      .where('memberships.ended_at BETWEEN ? AND ?', Date.current, 30.days.from_now)
  }
  scope :with_expired_membership, -> { 
    joins(:memberships)
      .where(memberships: { status: :expired })
  }
  scope :without_membership, -> { left_joins(:memberships).where(memberships: { id: nil }) }
  scope :search_by_contact, ->(query) { 
    where("first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR phone LIKE ?", 
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%") 
  }

  private

  def normalize_email
    self.email = nil if email.blank?
  end

  def must_have_active_membership
    return if new_record? # Skip à la création
    return if memberships.active.any?
    
    errors.add(:base, "Une adhésion active est obligatoire")
  end
end
