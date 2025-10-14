class User < ApplicationRecord
  attr_accessor :cgu, :privacy_policy, :created_by_admin
  after_create :generate_password_reset_token
  after_create :welcome_send
  before_validation :capitalize_names
  before_validation :set_full_name

  # Configuration du token de réinitialisation de mot de passe
  generates_token_for :password_reset, expires_in: 15.minutes do
    # On utilise le salt du mot de passe pour invalider le token si le mot de passe change
    password_salt&.last(10)
  end

  has_secure_password

  enum :system_role, %i[ super_admin admin volunteer user_connected ]

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
  
  # Relations directes (conservées pour compatibilité)
  has_many :product_orders
  has_many :orders

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, unless: :created_by_admin?, on: :create
  validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }, unless: :created_by_admin?
  validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }, unless: :created_by_admin?

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
      email_address: "deleted_#{id}@example.com",
      first_name: "Deleted",
      last_name: "User",
      full_name: "Deleted User",
      address: nil,
      phone_number: nil
    )

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
    return if user_connected?
    return if email_address.blank? # Don't send email if no email address

    if created_by_admin?
      UserMailer.welcome_by_admin(self, reset_password_url).deliver_later
    else
      UserMailer.welcome_email(self).deliver_later
    end
  end

  def formatted_registration_date
    if person&.has_active_membership?
      person.memberships.order(:created_at).last.created_at.strftime("%d/%m/%Y")
    else
      "Pas encore membre"
    end
  end

  def has_privileges?
    %w[admin super_admin volunteer].include?(self.system_role) # TODO: Think about how super_admin should be handled
  end

  def has_admin?
    %w[admin super_admin].include?(self.system_role)
  end

  def created_by_admin?
    @created_by_admin == true
  end


  def is_interested_in?(event_id)
    event_attendees.exists?(event_id: event_id)
  end

  def assign_basic_membership
      basic_membership = Membership.find_by(type_name: :basic)
      user_memberships.create(membership: basic_membership) if basic_membership
  end

  def has_higher_permissions?(other_user)
    Rails.logger.debug "has_higher_permissions? called with other_user: #{other_user.inspect}"
    return false if other_user.nil?

    # Get the integer values of the roles
    self_role_value = User.system_roles[self.system_role]
    other_role_value = User.system_roles[other_user.system_role]

    Rails.logger.debug "self_role_value: #{self_role_value}, other_role_value: #{other_role_value}"

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

  # Method for backward compatibility
  def full_name
    # Priorité à la Person liée, sinon utiliser les données User
    person&.full_name || self[:full_name] || begin
      first = first_name.to_s.strip
      last = last_name.to_s.strip

      if first.present? && last.present?
        "#{first} #{last}"
      elsif first.present?
        first
      elsif last.present?
        last
      else
        nil
      end
    end
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

  private

  def generate_password_reset_token
    generate_token_for(:password_reset)
  end

  def capitalize_names
    # Capitalize first letter of first_name only
    self.first_name = first_name.to_s.strip.capitalize if first_name.present?

    # Capitalize the entire last name if present
    if last_name.present?
      self.last_name = last_name.to_s.strip.upcase
    end
  end

  def set_full_name
    # Handle nil values and trim whitespace
    first = first_name.to_s.strip
    last = last_name.to_s.strip

    # Set full_name only if both first and last are present
    self.full_name = if first.present? && last.present?
                       "#{first.capitalize} #{last.upcase}"
    elsif first.present?
                       first.capitalize
    elsif last.present?
                       last.upcase
    else
                       nil
    end
  end
end
