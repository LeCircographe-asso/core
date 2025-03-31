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

  def welcome_send
    return if user_connected?

    if created_by_admin?
      UserMailer.welcome_by_admin(self, reset_password_url).deliver_now
    else
      UserMailer.welcome_email(self).deliver_now
    end
  end

  def formatted_registration_date
    if authenticated?
      user_memberships.order(:created_at).last.created_at.strftime("%d/%m/%Y")
    else
      "Pas encore membre"
    end
  end

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

  def password_reset_token
    Rails.application.message_verifier(:password_reset).generate(id, expires_in: 15.minutes)
  end

  def self.find_by_password_reset_token!(token)
    id = Rails.application.message_verifier(:password_reset).verify(token)
    find(id)
  end
end
