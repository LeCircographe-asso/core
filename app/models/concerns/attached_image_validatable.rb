# frozen_string_literal: true

# Validation partagée pour les attachments ActiveStorage image (GalleryPhoto#image,
# BoardMember#avatar, Partner#logo). Taille et types acceptés identiques partout.
module AttachedImageValidatable
  extend ActiveSupport::Concern

  MAX_UPLOAD_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

  private

  def validate_image_attachment(attachment)
    return unless attachment.attached?

    if attachment.blob.byte_size > MAX_UPLOAD_SIZE
      errors.add(attachment.name, "doit faire moins de #{MAX_UPLOAD_SIZE / 1.megabyte} Mo")
    end

    unless attachment.blob.content_type.in?(ALLOWED_CONTENT_TYPES)
      errors.add(attachment.name, "doit être une image (JPEG, PNG, WEBP ou GIF)")
    end
  end
end
