# frozen_string_literal: true

class Partner < ApplicationRecord
  include AttachedImageValidatable

  has_one_attached :logo

  validates :name, presence: true
  validate :validate_logo

  before_validation :set_display_order, on: :create

  scope :ordered, -> { order(:display_order, :created_at) }

  # Repli sans logo : initiales explicites si renseignées, sinon dérivées du nom.
  def initials_label
    (initials.presence || name.to_s.first(2)).to_s.upcase
  end

  private

  def validate_logo
    validate_image_attachment(logo)
  end

  def set_display_order
    self.display_order ||= self.class.maximum(:display_order).to_i + 1
  end
end
