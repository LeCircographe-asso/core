# frozen_string_literal: true

class Faq < ApplicationRecord
  LABELS = %w[avant_visite general adhesion contact].freeze

  LABEL_NAMES = {
    "avant_visite" => "Avant de te déplacer",
    "adhesion"     => "Adhérer & pratiquer",
    "general"      => "Lieu & horaires",
    "contact"      => "Écrire & proposer"
  }.freeze

  LABEL_PAGES = {
    "avant_visite" => "/adhesion",
    "adhesion"     => "/faq",
    "general"      => "/faq",
    "contact"      => "/faq"
  }.freeze

  validates :question, presence: true
  validates :answer,   presence: true
  validates :label,    presence: true, inclusion: { in: LABELS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered,    -> { order(:position, :created_at) }
  scope :by_label,   ->(label) { where(label: label).ordered }

  before_validation :set_position, on: :create

  private

  def set_position
    self.position ||= self.class.where(label: label).maximum(:position).to_i + 1
  end
end
