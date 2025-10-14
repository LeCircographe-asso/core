class Person < ApplicationRecord
  # Relations
  has_one :user, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :book_of_entries, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, allow_blank: true

  # Méthodes
  def full_name
    "#{first_name} #{last_name}"
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

  # Scopes
  scope :with_user_account, -> { joins(:user) }
  scope :without_user_account, -> { left_joins(:user).where(users: { id: nil }) }
  scope :by_name, ->(query) { where("first_name LIKE ? OR last_name LIKE ?",
                                        "%#{query}%", "%#{query}%") }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :with_phone, -> { where.not(phone: [ nil, "" ]) }
end
