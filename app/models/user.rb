# frozen_string_literal: true

class User < ApplicationRecord
  include Roleable
  include Dateable

  attr_accessor :cgu, :privacy_policy

  before_validation :ensure_person_for_new_record, on: :create
  after_create :generate_password_reset_token
  after_create :welcome_send

  # Configuration du token de réinitialisation de mot de passe
  generates_token_for :password_reset, expires_in: 15.minutes do
    # On utilise le salt du mot de passe pour invalider le token si le mot de passe change
    password_salt&.last(10)
  end

  has_secure_password

  enum :system_role, { super_admin: 0, admin: 1, volunteer: 2, web_visitor: 3 }

  alias_attribute :email, :email_address

  # Relation avec Person (nouvelle architecture)
  belongs_to :person

  # Relations Person-Based Architecture
  has_many :sessions, dependent: :destroy
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees

  # Relations via Person (nouvelles)
  has_many :memberships, through: :person
  has_many :payments, through: :person
  has_many :contributions, through: :person
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
  validates :person, presence: true
  validate :email_uniqueness_unless_person_email
  validates :cgu, acceptance: { message: :must_accept }, unless: :created_by_admin?
  validates :privacy_policy, acceptance: { message: :must_accept }, unless: :created_by_admin?

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
    update!(
      email_address: "deleted_#{id}@example.com"
    )

    # Anonymiser les données de la Person liée
    person&.update!(
      first_name: "Deleted",
      last_name: "User",
      address: nil,
      phone: nil,
      email: "deleted_#{id}@example.com"
    )

    # Deactivate any active memberships
    memberships.where(status: "active").find_each do |membership|
      membership.update!(status: "inactive")
    end
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
    return if Rails.env.test?
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
    %w[admin super_admin volunteer].include?(system_role)
  end

  def admin?
    %w[admin super_admin].include?(system_role)
  end

  def created_by_admin?
    created_by_admin == true
  end

  def has_higher_permissions?(other_user)
    return false if other_user.nil?

    # Get the integer values of the roles
    self_role_value = User.system_roles[system_role]
    other_role_value = User.system_roles[other_user.system_role]

    # Handle nil roles - nil means no permissions (lowest level)
    return false if self_role_value.nil?
    return true if other_role_value.nil?

    # Lower number means higher permissions in the enum
    self_role_value < other_role_value
  end

  def subordinate_roles
    current_role_value = User.system_roles[system_role]

    return [] if current_role_value.nil?

    # Get all roles with higher values (lower permissions) than current role
    User.system_roles.select { |_, value| value > current_role_value }.keys
  end

  def active_membership?
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
    # Return the raw value from the database
    self[:system_role]
  end

  # Date scopes (using created_at via Dateable)
  scope :today, -> { where(created_at: Date.current.beginning_of_day...Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: Date.current.beginning_of_week.beginning_of_day..Date.current.end_of_week.end_of_day) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month.beginning_of_day..Date.current.end_of_month.end_of_day) }
  scope :with_deleted, -> { all }

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

  def deleted?
    deleted == true || deleted_at.present?
  end

  def archive!
    return false if deleted?

    update!(deleted: true, deleted_at: Time.current)
    anonymize_personal_data
    true
  end

  def restore
    update(deleted: false, deleted_at: nil)
  end

  def restore!
    update!(deleted: false, deleted_at: nil)
  end

  # Standard destroy method - no soft deletion

  def email_uniqueness_unless_person_email
    return if email_address.blank?

    # Si on a une Person associée avec le même email, c'est OK
    return if person&.email == email_address

    # Sinon, vérifier l'unicité normale
    return unless User.where(email_address: email_address).where.not(id: id).exists?

    errors.add(:email_address, "est déjà utilisé")
  end

  # Check if user is interested in an event (Person-Based Architecture)
  def is_interested_in?(event_id)
    return false unless person

    person.attendances.exists?(event_id: event_id)
  end

  private

  def ensure_person_for_new_record
    return if person.present?

    self.person = Person.new(
      first_name: "Web",
      last_name: "User",
      email: email_address
    )
    person.skip_membership_validation = true
  end

  def generate_password_reset_token
    return if Rails.env.test?

    generate_token_for(:password_reset)
  end

  # Méthodes obsolètes supprimées - les noms sont maintenant gérés par Person
  # capitalize_names et set_full_name ne sont plus nécessaires
end
