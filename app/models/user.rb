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
  has_many :training_attendees
  has_many :payments, dependent: :destroy
  has_many :training_sessions, through: :training_attendees
  has_many :recorded_training_sessions, 
           class_name: 'TrainingSession',
           foreign_key: :recorded_by_id

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_secure_password
  validates :email_address, presence: true, uniqueness: true
  validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }
  validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }

  # after_create :welcome_send
  # def welcome_send
  #   UserMailer.welcome_email(self).deliver_now
  # end
  
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

  def active_circus_membership?
    circus_membership? && 
    user_memberships.where('expiration_date >= ?', Date.today)
                    .where(status: true)
                    .exists?
  end

  def current_subscription
    return nil unless active_circus_membership?
    
    user_memberships.where('expiration_date >= ?', Date.today)
                    .where(status: true)
                    .order(created_at: :desc)
                    .first
  end

  def can_train_today?
    return false if already_trained_today?
    return false unless active_circus_membership?
    true
  end

  def can_upgrade_subscription?
    return false unless circus_membership?
    return true if current_subscription.nil?
    
    current_sub = current_subscription.subscription_type
    return false if current_sub.name == 'annual'
    return false if current_sub.name == 'booklet' && current_subscription.remaining_entries.positive?
    
    true
  end

  # Pour gérer la transition membership -> circus_membership
  def upgrade_to_circus!(payment_params = nil)
    return false if circus_membership?
    
    transaction do
      update!(role: :circus_membership)
      
      # Créer l'adhésion circus si un paiement est fourni
      if payment_params
        payment = payments.create!(payment_params)
        user_memberships.create!(
          subscription_type: SubscriptionType.find_by(name: 'circus_membership'),
          payment: payment,
          status: true,
          expiration_date: 1.year.from_now
        )
      end
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Pour vérifier si on peut prendre un nouvel abonnement
  def can_take_subscription?(subscription_type)
    return false unless circus_membership?
    return true if current_subscription.nil?

    current_sub = current_subscription
    
    case subscription_type.name
    when 'daily'
      # On peut toujours prendre une journée si pas d'abonnement actif
      current_sub.nil?
    when 'booklet'
      # On peut prendre un carnet si on a une journée qui expire
      current_sub.subscription_type.name == 'daily'
    when 'trimestrial'
      # On peut passer d'une journée ou d'un carnet presque vide au trimestre
      current_sub.subscription_type.name == 'daily' ||
        (current_sub.subscription_type.name == 'booklet' && 
         current_sub.remaining_entries <= 2)
    when 'annual'
      # Pareil pour l'annuel
      ['daily', 'trimestrial'].include?(current_sub.subscription_type.name) ||
        (current_sub.subscription_type.name == 'booklet' && 
         current_sub.remaining_entries <= 2)
    end
  end

  # Pour l'affichage de la membership card
  def membership_status
    {
      role: role,
      active: active_circus_membership?,
      subscription: current_subscription&.subscription_details,
      expiration: current_subscription&.expiration_date,
      remaining_entries: current_subscription&.remaining_entries
    }
  end

  def allowed_paths
    NavigationRulesService.allowed_paths_for(role)
  end

  def default_path
    NavigationRulesService.default_path_for(role)
  end

  def can_access?(path)
    return true if role.in?(%w[admin godmode])
    allowed_paths.any? { |allowed| path.start_with?(allowed) }
  end

  def can?(action)
    NavigationRulesService.has_permission?(self, action)
  end

  def already_trained_today?
    training_attendees
      .joins(:training_session)
      .where(training_sessions: { date: Date.current })
      .exists?
  end

  scope :search, ->(query) {
    where("LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email_address) LIKE :q",
          q: "%#{query.downcase}%")
  }

  def full_name
    if first_name.present? || last_name.present?
      [first_name, last_name].compact.join(' ')
    else
      email_address
    end
  end
end
