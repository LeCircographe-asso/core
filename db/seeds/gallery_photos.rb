# Galerie initiale (staging/production) : les photos statiques de app/assets/images, même pool que le
# repli de pages/gallery et de `bin/rails gallery_photos:import_existing`. Importées en base pour rester
# affichées (et modifiables depuis l'admin) après les premiers uploads, ce qui désactive le repli statique.
# Appliqué seulement si GalleryPhoto est vide (voir Seeds::Profile::CONTENT_SEEDS).

base_images = %w[lelieu1.webp lelieu2.webp circus-img2.webp graff-img1.webp flowersZoomed.webp background.webp]
hero_images = Rails.root.glob("app/assets/images/hero_*.webp").map { |path| File.basename(path) }.sort

(base_images + hero_images).uniq.each do |filename|
  path = Rails.root.join("app/assets/images", filename)
  next warn("  ⚠️ gallery_photos.rb : #{filename} introuvable, ignoré") unless path.exist?

  File.open(path) do |io|
    photo = GalleryPhoto.new
    photo.image.attach(io: io, filename: filename, content_type: "image/webp")
    photo.save!
  end
end

puts "  #{GalleryPhoto.count} photos de galerie importées."
