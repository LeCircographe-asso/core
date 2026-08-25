# frozen_string_literal: true

class GalleryPhoto < ApplicationRecord
  include AttachedImageValidatable

  has_one_attached :image
  belongs_to :created_by_user, class_name: "User", optional: true

  validates :image, presence: true
  validate :validate_image

  before_validation :set_position, on: :create

  scope :ordered, -> { order(:position, :created_at) }

  # Toujours servi en WebP (mieux compressé que JPEG/PNG à qualité égale) quel
  # que soit le format d'origine — chargement rapide garanti côté public.
  def thumb
    image.variant(resize_to_fill: [ 400, 400 ], format: :webp, saver: { quality: 75 })
  end

  def full
    image.variant(resize_to_limit: [ 1600, 1600 ], format: :webp, saver: { quality: 82 })
  end

  private

  def validate_image
    validate_image_attachment(image)
  end

  def set_position
    self.position ||= self.class.maximum(:position).to_i + 1
  end
end
