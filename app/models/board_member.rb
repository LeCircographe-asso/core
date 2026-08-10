# frozen_string_literal: true

class BoardMember < ApplicationRecord
  include AttachedImageValidatable

  SOCIAL_PLATFORMS = %i[instagram linkedin behance].freeze

  has_one_attached :avatar

  validates :name, :role, presence: true
  validate :validate_avatar

  before_validation :set_display_order, on: :create

  scope :ordered, -> { order(:display_order, :created_at) }

  # {instagram: url, linkedin: url, behance: url} sans les entrées vides —
  # consommé par la vue publique (icônes réseaux sociaux du CA).
  def socials
    SOCIAL_PLATFORMS.index_with { |platform| public_send(:"#{platform}_url") }.compact
  end

  private

  def validate_avatar
    validate_image_attachment(avatar)
  end

  def set_display_order
    self.display_order ||= self.class.maximum(:display_order).to_i + 1
  end
end
