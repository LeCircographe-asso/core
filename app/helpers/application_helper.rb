# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
  include MembershipCardHelper

  def payment_method_options(include_pending: false)
    options = [
      [ t("payment_methods.cash", default: "Espèces"), "cash" ],
      [ t("payment_methods.card", default: "Carte bancaire"), "card" ],
      [ t("payment_methods.cheque", default: "Chèque"), "cheque" ],
      [ t("payment_methods.transfer", default: "Virement"), "transfer" ]
    ]
    options << [ t("payment_methods.offered", default: "Offert"), "offered" ] if current_user&.can_offer_items?
    options << [ t("payment_methods.pending", default: "À payer plus tard"), "pending" ] if include_pending
    options
  end

  def public_registration_enabled?
    Rails.application.config.x.public_registration_enabled
  end

  def account_claim_enabled?
    Rails.application.config.x.account_claim_enabled
  end

  HERO_IMAGE_ASSIGNMENTS_REQUEST_KEY = "_circographe.hero_image_assignments"
  HERO_IMAGE_POOL_REQUEST_KEY = "_circographe.hero_image_pool"

  def current_user
    return unless authenticated?

    Current.user
  end

  def authorized_roles
    %i[admin super_admin]
  end

  def admin_view?
    authenticated? && authorized_roles.include?(Current.user.system_role)
  end

  def render_card_component(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: "shared/card",
           locals: { title: title,
                     description: description,
                     image: image,
                     alt_text: alt_text,
                     link: link,
                     button_text: button_text }
  end

  def render_card_component_reverse(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: "shared/card_reverse",
           locals: { title: title,
                     description: description,
                     image: image,
                     alt_text: alt_text,
                     link: link,
                     button_text: button_text }
  end

  def flash_class(level)
    case level.to_sym
    when :notice, :success
      "bg-green-100 border-green-400 text-green-700"
    when :alert, :error
      "bg-red-100 border-red-400 text-red-700"
    when :warning
      "bg-yellow-100 border-yellow-400 text-yellow-700"
    else
      "bg-blue-100 border-blue-400 text-blue-700"
    end
  end

  def active_class(path)
    current_page?(path) ? "bg-gray-900 text-white" : "text-gray-300 hover:bg-gray-700 hover:text-white"
  end

  def format_phone_number(phone)
    return "Non renseigné" if phone.blank?

    # Format: +33 6 12 34 56 78
    phone.gsub(/(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/, '\1 \2 \3 \4 \5')
  end

  def hero_image(identifier = :default)
    assignments = hero_image_assignments_storage
    return assignments[identifier] if assignments.key?(identifier)

    images = hero_image_pool
    fallback = fallback_hero_image(images)
    assignments[identifier] = images.sample || fallback
  end

  def available_hero_images(except: [])
    exclusions = Array(except).map(&:to_s)
    pool = hero_image_pool.reject { |image| exclusions.include?(image.to_s) }
    return pool if pool.any?

    fallback = fallback_hero_image
    fallback && exclusions.exclude?(fallback.to_s) ? [ fallback ] : []
  end

  # Filenames under app/assets/images/ (same pool as hero_image). Sorted for stable order.
  # Swiper receives several slides but only the first image uses eager loading.
  def news_carousel_image_sources(limit: 12)
    max_slides = limit.to_i.clamp(1, 24)
    hero_image_pool.uniq.sort.take(max_slides)
  end

  def asset_available?(logical_path)
    return false if logical_path.blank?

    if (assembly = Rails.application.assets).respond_to?(:load_path) && assembly.load_path.find(logical_path).present?
      return true
    end

    asset_full_path = Rails.root.join("app/assets/images", logical_path)
    asset_full_path.exist?
  rescue StandardError
    false
  end

  private

  def hero_image_assignments_storage
    raise "hero_image_* helpers require request" unless request.respond_to?(:env)

    request.env[HERO_IMAGE_ASSIGNMENTS_REQUEST_KEY] ||= {}
  end

  def hero_image_pool
    raise "hero_image_* helpers require request" unless request.respond_to?(:env)

    request.env[HERO_IMAGE_POOL_REQUEST_KEY] ||= begin
      files = Rails.root.glob("app/assets/images/hero_*.webp").map { |path| File.basename(path) }
      files.select! { |file| asset_available?(file) }
      fallback = fallback_hero_image(files)
      files << fallback if fallback && files.exclude?(fallback)
      files
    end
  end

  def fallback_hero_image(existing = nil)
    candidate = "hero_01.webp"
    return candidate if (existing || hero_image_pool_without_cache).include?(candidate)

    asset_available?(candidate) ? candidate : existing&.first
  end

  def hero_image_pool_without_cache
    Rails.root.glob("app/assets/images/hero_*.webp").map { |path| File.basename(path) }
  end
end
