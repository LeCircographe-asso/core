class User < ApplicationRecord
  attr_accessor :cgu, :private_policy

  enum :role, %i[guest membership circus_membership volunteer admin godmode], default: :guest

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
  
  def active_membership?
    user_memberships.active.exists?
  end
  
  def active_circus_membership?
    user_memberships.active.joins(:subscription_type)
                   .where(subscription_types: { category: 'circus_membership' }).exists?
  end
  
  def can_access_training?
    active_circus_membership? && user_memberships.active.joins(:subscription_type)
                                               .where(subscription_types: { category: ['ten_pass', 'trimester', 'annual'] }).exists?
  end

  def generate_password_reset_token!
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!
  end

  def password_reset_token_valid?
    password_reset_sent_at.present? && password_reset_sent_at > 2.hours.ago
  end

  def formatted_registration_date
    if authenticated?
      user_memberships.order(:created_at).last.created_at.strftime("%d/%m/%Y")
    else
      "Pas encore membre"
    end
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

  scope :published, -> { where(published: true) }

  def has_privileges?
    %w[admin godmode volunteer].include?(self.role)
  end

  def is_interested_in?(event_id)
    events = self.event_attendees
    events.each do |event|
      if event.event_id == event_id
        return true
      end
    end
    false
  end
end
