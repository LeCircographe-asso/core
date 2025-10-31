class MembershipType < ApplicationRecord
  include Priceable
  include Humanizable
  include Versionable
  include Categorizable
  
  # Relations
  has_many :memberships, dependent: :restrict_with_error
  has_many :subscription_plans, dependent: :destroy
  belongs_to :created_by_user, class_name: "User", optional: true

  # Validations
  validates :name, presence: true, uniqueness: { scope: :version }
  validates :category, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :effective_from, presence: true

  # Enum pour les catégories selon le domain_model_circographe.md
  enum :category, {
    basic: 0,
    circus: 1,
    event: 2
  }

  # Méthodes
  def circus?
    category == "circus"
  end

  def basic?
    category == "basic"
  end
  # (price_euros, category_display_name, current_version? maintenant dans les modules)

  def create_price_change!(new_price_cents, effective_from: Date.current, reason: nil, user: nil)
    # Fermer la version actuelle
    update!(effective_until: effective_from - 1.day)

    # Créer la nouvelle version
    new_version = dup
    new_version.assign_attributes(
      version: version + 1,
      price_cents: new_price_cents,
      effective_from: effective_from,
      effective_until: nil,
      created_by_user: user,
      change_reason: reason
    )
    new_version.save!

    new_version
  end

  def price_evolution
    # Récupérer l'historique des prix pour ce type d'adhésion
    MembershipType.where(name: name).price_history
  end

  def price_change_percentage(from_date, to_date)
    old_price = MembershipType.where(name: name, effective_from: from_date).first&.price_cents
    new_price = MembershipType.where(name: name, effective_from: to_date).first&.price_cents

    return nil unless old_price && new_price && old_price > 0

    ((new_price - old_price).to_f / old_price * 100).round(2)
  end

  # Scopes
  scope :circus_types, -> { where(category: :circus) }
  scope :basic_types, -> { where(category: :basic) }
  scope :by_price, -> { order(:price_cents) }
  scope :active, -> { joins(:memberships).distinct }
  scope :current_versions, -> { where(effective_until: nil) }
  scope :effective_on, ->(date) { where("effective_from <= ? AND (effective_until IS NULL OR effective_until >= ?)", date, date) }
  scope :price_history, -> { order(:effective_from, :version) }

  # Méthodes de classe pour créer les types par défaut
  def self.create_default_types!
    find_or_create_by(name: "Adhésion Basique", version: 1) do |mt|
      mt.category = :basic
      mt.price_cents = 1500 # 15€
      mt.description = "Adhésion de base à l'association"
      mt.effective_from = Date.current
    end

    find_or_create_by(name: "Adhésion Cirque Complète", version: 1) do |mt|
      mt.category = :circus
      mt.price_cents = 2500 # 25€
      mt.description = "Adhésion complète avec accès aux cours de cirque"
      mt.effective_from = Date.current
    end

    find_or_create_by(name: "Adhésion Cirque Réduite", version: 1) do |mt|
      mt.category = :circus
      mt.price_cents = 2000 # 20€
      mt.description = "Adhésion cirque à tarif réduit (étudiants, chômeurs, etc.)"
      mt.effective_from = Date.current
    end
  end
end
