# frozen_string_literal: true

namespace :gallery_photos do
  desc "Importe une fois les photos statiques actuelles de la galerie (app/assets/images) dans GalleryPhoto"
  task import_existing: :environment do
    # Même pool que l'ancien app/views/pages/gallery.html.erb : les 6 images de
    # base + tout le pool hero_*.webp (utilisé aléatoirement avant la Phase 1 DB).
    base_images = %w[lelieu1.webp lelieu2.webp circus-img2.webp graff-img1.webp flowersZoomed.webp background.webp]
    hero_images = Rails.root.glob("app/assets/images/hero_*.webp").map { |path| File.basename(path) }.sort
    files = (base_images + hero_images).uniq

    already_imported = ActiveStorage::Blob.where(filename: files).pluck(:filename)

    files.each do |filename|
      if already_imported.include?(filename)
        puts "  ↷ déjà importé, ignoré : #{filename}"
        next
      end

      path = Rails.root.join("app/assets/images", filename)
      unless File.exist?(path)
        puts "  ⚠️ introuvable, ignoré : #{filename}"
        next
      end

      photo = GalleryPhoto.new
      photo.image.attach(io: File.open(path), filename: filename)

      if photo.save
        puts "  ✅ importé : #{filename}"
      else
        puts "  ❌ échec (#{filename}) : #{photo.errors.full_messages.to_sentence}"
      end
    end

    puts "Terminé — #{GalleryPhoto.count} photo(s) en base."
  end
end
