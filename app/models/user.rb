class User < ApplicationRecord
  include Roleable
  include Dateable

  attr_accessor :cgu, :privacy_policy
  after_create :generate_password_reset_token
  after_create :welcome_send

  # Configuration du token de réinitialisation de mot de passe
  generates_token_for :password_reset, expires_in: 15.minutes do
    # On utilise le salt du mot de passe pour invalider le token si le mot de passe change
    password_salt&.last(10)
  end

  has_secure_password

  enum :system_role, %i[ super_admin admin volunteer web_visitor ]

  alias_attribute :email, :email_address

  # Relation avec Person (nouvelle architecture)
  belongs_to :person, optional: true

  # Relations Person-Based Architecture
  has_many :sessions, dependent: :destroy
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees

  # Relations via Person (nouvelles)
  has_many :memberships, through: :person
  has_many :payments, through: :person
  has_many :book_of_entries, through: :person
  has_many :attendances, through: :person

  # Délégation des attributs personnels vers Person
  delegate :first_name, :last_name, :full_name, :phone, :email, :address,
           :birth_date, :emergency_contact_name, :emergency_contact_phone,
           :notes, :occupation, :specialty, :image_rights, :get_involved,
           :dyslexic_font, :zip_code, :town, :country,
           to: :person, prefix: false, allow_nil: true

  # Override newsletter_subscribed to read from NewsletterSubscriber
  def newsletter_subscribed
    return false unless person.present? && person.email.present?
    person.newsletter_subscribed?
  end

  normalizes :email_address, with: ->(e) { e&.strip&.downcase }

  validates :email_address, presence: true
  validate :email_uniqueness_unless_person_email
  validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }, unless: :created_by_admin?
  validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }, unless: :created_by_admin?

  # (can_edit_member_numbers? maintenant dans le module Roleable)

  # Override destroy method from SoftDeletable to handle payments
  # def destroy
  #   if has_active_payments?
  #     handle_deletion_with_payments
  #   else
  #     super # Call SoftDeletable's destroy method
  #     anonymize_personal_data
  #   end
  # end

  # Anonymize personal data after soft deletion
  def anonymize_personal_data
    update_columns(
      email_address: "deleted_#{id}@example.com"
    )

    # Anonymiser les données de la Person liée
    if person
      person.update_columns(
        first_name: "Deleted",
        last_name: "User",
        address: nil,
        phone: nil,
        email: "deleted_#{id}@example.com"
      )
    end

    # Deactivate any active memberships
    user_memberships.where(status: "active").update_all(status: "inactive")
  end

  # Check if the user has any active payments
  def has_active_payments?
    payments.active.exists?
  end

  # Handle deletion when user has payments
  def handle_deletion_with_payments
    super # Call SoftDeletable's destroy method

    # Mark all of the user's payments as cancelled
    payments.each do |payment|
      payment.handle_user_deletion if payment.respond_to?(:handle_user_deletion)
    end

    anonymize_personal_data
  end

  def welcome_send
    return if web_visitor?
    return if email_address.blank? # Don't send email if no email address

    # Skip email sending in seeds
    return if caller.any? { |line| line.include?("db/seeds") }

    if created_by_admin?
      # Generate password reset URL for admin-created users
      reset_url = Rails.application.routes.url_helpers.edit_password_url(token: password_reset_token)
      UserMailer.welcome_by_admin(self, reset_url).deliver_later
    else
      UserMailer.welcome_email(self).deliver_later
    end
  end

  def has_privileges?
    %w[admin super_admin volunteer].include?(self.system_role)
  end

  def has_admin?
    %w[admin super_admin].include?(self.system_role)
  end

  def created_by_admin?
    created_by_admin == true
  end
  def has_higher_permissions?(other_user)
    Rails.logger.debug "has_higher_permissions? called with other_user: #{other_user.inspect}"
    return false if other_user.nil?

    # Get the integer values of the roles
    self_role_value = User.system_roles[self.system_role]
    other_role_value = User.system_roles[other_user.system_role]

    Rails.logger.debug "self_role_value: #{self_role_value}, other_role_value: #{other_role_value}"

    # Handle nil roles - nil means no permissions (lowest level)
    return false if self_role_value.nil?
    return true if other_role_value.nil?

    # Lower number means higher permissions in the enum
    self_role_value < other_role_value
  end

  def inferior_rights
    Rails.logger.debug "inferior_rights called"
    current_role_value = User.system_roles[system_role]
    Rails.logger.debug "current_role_value: #{current_role_value.inspect}"

    return [] if current_role_value.nil?

    # Get all roles with higher values (lower permissions) than current role
    result = User.system_roles.select { |_, value| value > current_role_value }.keys
    Rails.logger.debug "inferior_rights result: #{result.inspect}"

    result
  end

  def active_subscription?
    person&.has_active_membership? || false
  end

  def self.find_by_password_reset_token!(token)
    id = Rails.application.message_verifier(:password_reset).verify(token)
    find(id)
  end

  # Method for backward compatibility - now delegated to person
  def full_name
    person&.full_name
  end

  # Méthode pour obtenir le nom de la personne (nouvelle architecture)
  def person_name
    person&.full_name
  end

  def system_role_before_type_cast
    Rails.logger.debug "system_role_before_type_cast called"
    Rails.logger.debug "self: #{self.inspect}"
    Rails.logger.debug "self.system_role: #{self.system_role.inspect}"

    # Return the raw value from the database
    self[:system_role]
  end

  # Date scopes (using created_at via Dateable)
  scope :today, -> { where("created_at >= ? AND created_at < ?", Date.current.beginning_of_day, Date.current.end_of_day) }
  scope :this_week, -> { where("created_at >= ? AND created_at <= ?", Date.current.beginning_of_week.beginning_of_day, Date.current.end_of_week.end_of_day) }
  scope :this_month, -> { where("created_at >= ? AND created_at <= ?", Date.current.beginning_of_month.beginning_of_day, Date.current.end_of_month.end_of_day) }

  # Class method to find or create a user with the same email
  def self.find_or_create_with_identity(email:, **attributes)
    existing_user = with_deleted.find_by(email_address: email.strip.downcase)
    if existing_user&.deleted?
      existing_user.restore
      existing_user.update(attributes)
      return existing_user
    end
    create(email_address: email, **attributes)
  end

  # Standard destroy method - no soft deletion
  def destroy
    # Transfer payments to admin user before deletion
    admin_user = User.find_by(system_role: :admin)
    if admin_user && payments.exists?
      payments.update_all(user_id: admin_user.id)
    end
    super # Standard ActiveRecord destroy
  end

  def email_uniqueness_unless_person_email
    return if email_address.blank?

    # Si on a une Person associée avec le même email, c'est OK
    if person&.email == email_address
      return
    end

    # Sinon, vérifier l'unicité normale
    if User.where(email_address: email_address).where.not(id: id).exists?
      errors.add(:email_address, "est déjà utilisé")
    end
  end

  # Check if user is interested in an event (Person-Based Architecture)
  def is_interested_in?(event_id)
    return false unless person

    person.attendances.exists?(event_id: event_id)
  end

  private

  def generate_password_reset_token
    generate_token_for(:password_reset)
  end

  # Méthodes obsolètes supprimées - les noms sont maintenant gérés par Person
  # capitalize_names et set_full_name ne sont plus nécessaires
end
