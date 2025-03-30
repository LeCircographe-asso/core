class User < ApplicationRecord
  attr_accessor :cgu, :privacy_policy
  # after_create :assign_membership
  after_create :generate_unsubscribe_token
  after_create :welcome_send

  enum :system_role, %i[ super_admin admin volunteer user_connected ]

  alias_attribute :email, :email_address
  has_many :sessions, dependent: :destroy
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees
  has_many :user_memberships, dependent: :destroy


  has_many :user
  has_many :attendance_lists, through: :attendances
  has_many :product_orders
  has_many :payments

  has_many :memberships, through: :user_memberships
  has_many :product_orders
  has_many :payments


  has_many :book_of_entries
  has_many :orders

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_secure_password
  validates :email_address, presence: true, uniqueness: true
  validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }
  validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }
  validates :password_reset_token, presence: true, if: -> { password_reset_sent_at.present? }


  # Génère un token de réinitialisation de mot de passe et sauvegarde l'utilisateur
  def generate_password_reset_token!
    Rails.logger.info "----- Génération du token -----"
    Rails.logger.info "Email de l'utilisateur : #{self.email_address}"
  
    # Génération du token et mise à jour de l'horodatage
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
  
    # Journaliser les valeurs pour identifier les problèmes potentiels
    Rails.logger.info "Token généré : #{self.password_reset_token}"
    Rails.logger.info "Horodatage de l'envoi : #{self.password_reset_sent_at}"
  
    save!
    Rails.logger.info "Reset token et timestamp enregistrés avec succès pour l'utilisateur #{self.email_address}."
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

  def welcome_send
    return if user_connected?

    if created_by_admin?
      UserMailer.welcome_by_admin(self, reset_password_url).deliver_later
    end
    UserMailer.welcome_email(self).deliver_later
  end

  def formatted_registration_date
    if authenticated?
      user_memberships.order(:created_at).last.created_at.strftime("%d/%m/%Y")
    else
      "Pas encore membre"
    end
  end

  def clear_password_reset_token!
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    save!
  end

  def reset_password_url(generate_password_reset_token)
    generate_password_reset_token! unless password_reset_token.present?
    Rails.application.routes.url_helpers.edit_password_url(token: @user.generate_password_reset_token, host: "https://lecircographe.fr")
  end

  scope :published, -> { where(published: true) }

  def has_privileges?
    %w[admin super_admin volunteer].include?(self.system_role)
  end

  def has_admin?
    %w[admin super_admin].include?(self.system_role)
  end


  def is_interested_in?(event_id)
    event_attendees.exists?(event_id: event_id)
  end

  def assign_basic_membership
      basic_membership = Membership.find_by(type_name: :basic)
      user_memberships.create(membership: basic_membership) if basic_membership
  end

  def has_higher_permissions?(other_user)
    self.system_role_before_type_cast < other_user.system_role_before_type_cast
  end

  def inferior_rights
    levels_of_right = self.system_role_before_type_cast
    ((levels_of_right + 1)..3).map { |level| User.system_roles.key(level) }
  end

  def active_subscription?
    user_memberships.exists?(status: "active")
  end


  private

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.base64(16)
  end



  # def assign_membership
  #   if self.memberships.empty?
  #     no_member_membership = Membership.find_by(type_name: :no_member)
  #     user_memberships.create(membership: no_member_membership) if no_member_membership
  #   end
end
