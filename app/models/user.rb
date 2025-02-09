class User < ApplicationRecord
  attr_accessor :cgu, :private_policy

  # Nouveaux rôles
  enum :role, {
    guest: 0,      # Utilisateur inscrit basique
    member: 1,     # Membre avec droits basiques
    volunteer: 2,  # Peut gérer les présences et adhésions
    admin: 3,      # Accès complet admin
    godmode: 4     # Super admin
  }, default: :guest

  alias_attribute :email, :email_address

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :sessions, dependent: :destroy
  has_many :created_events, class_name: "Event", foreign_key: "creator_id", dependent: :destroy
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees
  has_many :user_memberships, dependent: :destroy
  has_many :subscription_types, through: :user_memberships
  has_many :training_attendees, through: :user_memberships
  has_many :payments, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_secure_password
  
  # Validations de base
  validates :email_address, presence: true, 
                          uniqueness: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas une adresse email valide" }
  validates :first_name, presence: true
  validates :last_name, presence: true
  
  # Validations pour l'inscription
  validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }
  validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }
  
  # Méthodes utiles
  def full_name
    "#{first_name} #{last_name}"
  end

  # Méthodes de vérification des adhésions
  def active_membership?
    user_memberships.active.exists?
  end
  
  def active_basic_membership?
    user_memberships.active.joins(:subscription_type)
                   .where(subscription_types: { category: :basic_membership }).exists?
  end
  
  def active_circus_membership?
    user_memberships.active.joins(:subscription_type)
                   .where(subscription_types: { category: :circus_membership }).exists?
  end

  # Méthodes de vérification d'accès
  def can_access_training?
    active_circus_membership? && user_memberships.active.joins(:subscription_type)
                                               .where(subscription_types: { category: [:day_pass, :ten_sessions, :quarterly, :yearly] })
                                               .exists?
  end

  def has_valid_training_pass?
    user_memberships.active.joins(:subscription_type)
                   .where(subscription_types: { category: [:day_pass, :ten_sessions, :quarterly, :yearly] })
                   .exists?
  end

  # Nouvelles méthodes de permission basées sur le rôle
  def can_manage_users?
    admin? || godmode?
  end

  def can_manage_memberships?
    volunteer? || admin? || godmode?
  end

  def can_manage_attendance?
    volunteer? || admin? || godmode?
  end

  def can_view_statistics?
    admin? || godmode?
  end

  def can_manage_events?
    admin? || godmode?
  end

  def can_edit_settings?
    godmode?
  end

  # Méthode générique de vérification des privilèges
  def has_privileges?
    volunteer? || admin? || godmode?
  end

  # Méthodes pour la réinitialisation du mot de passe
  def generate_password_reset_token!
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!
  end

  def password_reset_token_valid?
    password_reset_sent_at.present? && password_reset_sent_at > 2.hours.ago
  end

  def reset_password!(password, password_confirmation)
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    self.password = password
    self.password_confirmation = password_confirmation
    save!
  end

  def clear_password_reset_token!
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    save!
  end

  # Autres méthodes utilitaires
  def formatted_registration_date
    if active_membership?
      user_memberships.order(:created_at).last.created_at.strftime("%d/%m/%Y")
    else
      "Pas encore membre"
    end
  end

  def is_interested_in?(event_id)
    event_attendees.exists?(event_id: event_id)
  end

  # Scopes utiles
  scope :with_privileges, -> { where(role: [:volunteer, :admin, :godmode]) }
  scope :active_members, -> { where(role: [:member, :volunteer, :admin, :godmode]) }
  scope :administrators, -> { where(role: [:admin, :godmode]) }
  scope :guests, -> { where(role: :guest) }
  scope :members, -> { where(role: :member) }
  scope :volunteers, -> { where(role: :volunteer) }
  scope :admins, -> { where(role: :admin) }
  scope :godmodes, -> { where(role: :godmode) }
end
