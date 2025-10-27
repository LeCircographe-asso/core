class Person < ApplicationRecord
  # Relations (MODIFIER dependent pour protéger données financières)
  has_one :user, dependent: :nullify
  has_many :memberships, dependent: :restrict_with_error  # ✅ Empêcher suppression
  has_many :payments, dependent: :restrict_with_error     # ✅ Empêcher suppression
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
  # SUPPRIMÉE : Une Person peut exister sans adhésion (newsletter, prospects, etc.)
  # validate :must_have_active_membership, unless: :skip_membership_validation

  # Normalisation des données
  before_validation :normalize_email

  # Callbacks newsletter
  before_create :generate_newsletter_token, if: :newsletter_subscribed?
  before_update :generate_newsletter_token, if: -> {
    newsletter_subscribed? && newsletter_unsubscribe_token.blank?
  }

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
    when "CIRQUE", "C"
                       "Cirque"
    when "BASIQUE", "U", "BASIC"
                       "Basique"
    else
                       "Basique" # Par défaut
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
  scope :active, -> { where(deleted_at: nil) }
  scope :archived, -> { where.not(deleted_at: nil) }
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
                 .having("COUNT(*) = 1")
                 .select(:id)
      )
    )
  }

  scope :with_expiring_membership, -> {
    joins(:memberships)
      .where(memberships: { status: :active })
      .where("memberships.ended_at BETWEEN ? AND ?", Date.current, 30.days.from_now)
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

  # Soft delete
  def archive!
    return false if has_financial_data?
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def archived?
    deleted_at.present?
  end

  # Newsletter scopes
  scope :newsletter_subscribers, -> {
    active.where(newsletter_subscribed: true).where.not(email: [ nil, "" ])
  }

  # Méthodes utilitaires pour la sécurité des fusions
  def safe_to_merge_with?(other_person)
    return false if other_person.nil?
    return false if id == other_person.id
    
    # Si les deux ont des Users différents, fusion dangereuse
    if user.present? && other_person.user.present? && user.id != other_person.user.id
      return false
    end
    
    true
  end

  def can_be_claimed_by?(email_to_check)
    return false if user.present? # Déjà lié à un User
    return false if email.blank? # Pas d'email
    return false if email.downcase != email_to_check.downcase # Email différent
    true
  end

  private

  def normalize_email
    self.email = nil if email.blank?
  end

  def must_have_active_membership
    return if new_record? # Skip à la création
    return if memberships.active.any?
    return if skip_membership_validation # Skip si explicitement demandé

    errors.add(:base, "Une adhésion active est obligatoire")
  end

  def has_financial_data?
    payments.exists? || memberships.exists?
  end

  def generate_newsletter_token
    self.newsletter_unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end
end
