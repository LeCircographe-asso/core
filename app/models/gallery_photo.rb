# frozen_string_literal: true

class GalleryPhoto < ApplicationRecord
  MAX_UPLOAD_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

  has_one_attached :image
  belongs_to :created_by_user, class_name: "User", optional: true

  validates :image, presence: true
  validate :image_within_size_limit
  validate :image_has_allowed_content_type

  scope :ordered, -> { order(created_at: :desc) }

  # Toujours servi en WebP (mieux compressé que JPEG/PNG à qualité égale) quel
  # que soit le format d'origine — chargement rapide garanti côté public.
  def thumb
    image.variant(resize_to_fill: [ 400, 400 ], format: :webp, saver: { quality: 75 })
  end

  def full
    image.variant(resize_to_limit: [ 1600, 1600 ], format: :webp, saver: { quality: 82 })
  end

  private

  def image_within_size_limit
    return unless image.attached?
    return if image.blob.byte_size <= MAX_UPLOAD_SIZE

    errors.add(:image, "doit faire moins de #{MAX_UPLOAD_SIZE / 1.megabyte} Mo")
  end

  def image_has_allowed_content_type
    return unless image.attached?
    return if image.blob.content_type.in?(ALLOWED_CONTENT_TYPES)

    errors.add(:image, "doit être une image (JPEG, PNG, WEBP ou GIF)")
  end
end
