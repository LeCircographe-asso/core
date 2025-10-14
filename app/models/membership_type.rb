class MembershipType < ApplicationRecord
  # Relations
  has_many :memberships, dependent: :restrict_with_error
  has_many :subscription_plans, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  # Enum pour les catégories selon le domain_model_circographe.md
  enum :category, {
    basic: 0,
    circus_full: 1,
    circus_reduced: 2
  }

  # Méthodes
  def circus?
    circus_full? || circus_reduced?
  end

  def basic?
    category == "basic"
  end

  def price_euros
    price_cents / 100.0
  end

  def price_euros=(value)
    self.price_cents = (value.to_f * 100).round
  end

  # Scopes
  scope :circus_types, -> { where(category: [ :circus_full, :circus_reduced ]) }
  scope :basic_types, -> { where(category: :basic) }
  scope :by_price, -> { order(:price_cents) }
  scope :active, -> { joins(:memberships).distinct }

  # Méthodes de classe pour créer les types par défaut
  def self.create_default_types!
    find_or_create_by(name: "Adhésion Basique") do |mt|
      mt.category = :basic
      mt.price_cents = 1500 # 15€
      mt.description = "Adhésion de base à l'association"
    end

    find_or_create_by(name: "Adhésion Cirque Complète") do |mt|
      mt.category = :circus_full
      mt.price_cents = 2500 # 25€
      mt.description = "Adhésion complète avec accès aux cours de cirque"
    end

    find_or_create_by(name: "Adhésion Cirque Réduite") do |mt|
      mt.category = :circus_reduced
      mt.price_cents = 2000 # 20€
      mt.description = "Adhésion cirque à tarif réduit (étudiants, chômeurs, etc.)"
    end
  end
end
