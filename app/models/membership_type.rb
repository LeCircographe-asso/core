class MembershipType < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration, presence: true
  validates :category, presence: true, inclusion: { in: %w[membership circus_membership] }

  # Scopes
  scope :membership, -> { where(category: 'membership') }
  scope :circus, -> { where(category: 'circus_membership') }
  scope :active, -> { where(active: true) }

  # Méthodes
  def self.default_membership
    membership.find_by(name: 'basic_membership')
  end

  def self.default_circus
    circus.find_by(name: 'circus_membership')
  end
end 