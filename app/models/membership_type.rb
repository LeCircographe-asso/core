# frozen_string_literal: true

class MembershipType < ApplicationRecord
  include RateKindable
  include Priceable
  include Humanizable
  include Versionable
  include Categorizable

  # Relations
  has_many :memberships, dependent: :restrict_with_error
  has_many :contribution_formulas, dependent: :destroy
  has_many :price_change_logs, as: :loggable, dependent: :destroy
  belongs_to :created_by_user, class_name: "User", optional: true

  # Validations
  validates :name, presence: true, uniqueness: { scope: :version }
  validates :category, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :effective_from, presence: true

  # Catégories — voir docs/glossary.md.
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

  # Change de prix. Si la version courante n'a jamais été vendue (aucune
  # Membership dessus), la correction se fait en place — pas de nouvelle ligne,
  # le catalogue reste propre. Si elle a déjà été vendue, on ferme cette version
  # et on en ouvre une nouvelle (les Membership existantes gardent leur ancien
  # prix, inchangé). Dans tous les cas, la tentative est tracée dans
  # PriceChangeLog — y compris les corrections mergées, pour garder une trace
  # consultable des tarifs testés mais jamais vendus.
  def create_price_change!(new_price_cents, effective_from: Date.current, reason: nil, user: nil)
    old_price_cents = price_cents

    result = if memberships.empty?
      update!(price_cents: new_price_cents, change_reason: reason, created_by_user: user)
      self
    else
      update!(effective_until: effective_from - 1.day)

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

    PriceChangeLog.log(self, user, result.equal?(self) ? "merged" : "versioned",
                        old_price_cents: old_price_cents, new_price_cents: new_price_cents, reason: reason)

    result
  end

  # Ferme la version courante sans en ouvrir de nouvelle : le produit n'est
  # plus proposé aux nouveaux achats (exclu de current_versions/available_for)
  # mais les Membership déjà créées dessus restent intactes.
  def archive!(effective_until: Date.current, user: nil)
    update!(effective_until: effective_until)
    PriceChangeLog.log(self, user, "archived", price_cents: price_cents)
    self
  end

  # Rouvre une version archivée par erreur. Refuse si une version plus
  # récente du même nom est déjà courante — on ne veut jamais deux versions
  # « current » simultanées pour un même type d'adhésion.
  def unarchive!(user: nil)
    if self.class.where(name: name).current_versions.where.not(id: id).exists?
      errors.add(:base, "Une version plus récente de ce type d'adhésion est déjà active")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(effective_until: nil)
    PriceChangeLog.log(self, user, "unarchived", price_cents: price_cents)
    self
  end

  def price_evolution
    # Récupérer l'historique des prix pour ce type d'adhésion
    MembershipType.where(name: name).price_history
  end

  def price_change_percentage(from_date, to_date)
    old_price = MembershipType.where(name: name, effective_from: from_date).first&.price_cents
    new_price = MembershipType.where(name: name, effective_from: to_date).first&.price_cents

    return nil unless old_price && new_price && old_price.positive?

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

  def self.available_for(person)
    current_versions.for_rate_kinds(person.allowed_rate_kinds)
  end

  # Méthodes de classe pour créer les types par défaut
  def self.create_default_types!
    find_or_create_by(name: "Adhésion Basique", version: 1) do |mt|
      mt.category = :basic
      mt.price_cents = 1500 # 15€
      mt.rate_kind = "standard"
      mt.description = "Adhésion de base à l'association"
      mt.effective_from = Date.current
    end

    find_or_create_by(name: "Adhésion Cirque Complète", version: 1) do |mt|
      mt.category = :circus
      mt.price_cents = 2500 # 25€
      mt.rate_kind = "standard"
      mt.description = "Adhésion complète avec accès aux cours de cirque"
      mt.effective_from = Date.current
    end

    find_or_create_by(name: "Adhésion Cirque Réduite", version: 1) do |mt|
      mt.category = :circus
      mt.price_cents = 2000 # 20€
      mt.rate_kind = "reduced"
      mt.description = "Adhésion cirque à tarif réduit (étudiants, chômeurs, etc.)"
      mt.effective_from = Date.current
    end
  end
end
