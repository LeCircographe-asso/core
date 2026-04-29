module ApplicationHelper
  include Pagy::Frontend

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
    render partial: 'shared/card',
           locals: { title: title,
                     description: description,
                     image: image,
                     alt_text: alt_text,
                     link: link,
                     button_text: button_text }
  end

  def render_card_component_reverse(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: 'shared/card_reverse',
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
      'bg-green-100 border-green-400 text-green-700'
    when :alert, :error
      'bg-red-100 border-red-400 text-red-700'
    when :warning
      'bg-yellow-100 border-yellow-400 text-yellow-700'
    else
      'bg-blue-100 border-blue-400 text-blue-700'
    end
  end

  def active_class(path)
    current_page?(path) ? 'bg-gray-900 text-white' : 'text-gray-300 hover:bg-gray-700 hover:text-white'
  end

  def format_phone_number(phone)
    return 'Non renseigné' if phone.blank?

    # Format: +33 6 12 34 56 78
    phone.gsub(/(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/, '\1 \2 \3 \4 \5')
  end

  def hero_image(identifier = :default)
    @hero_image_assignments ||= {}
    return @hero_image_assignments[identifier] if @hero_image_assignments.key?(identifier)

    images = hero_image_pool
    fallback = fallback_hero_image(images)
    @hero_image_assignments[identifier] = images.sample || fallback
  end

  def available_hero_images(except: [])
    exclusions = Array(except).map(&:to_s)
    pool = hero_image_pool.reject { |image| exclusions.include?(image.to_s) }
    return pool if pool.any?

    fallback = fallback_hero_image
    fallback && !exclusions.include?(fallback.to_s) ? [fallback] : []
  end

  def asset_available?(logical_path)
    return false if logical_path.blank?

    if (assembly = Rails.application.assets)&.respond_to?(:load_path) && assembly.load_path.find(logical_path).present?
      return true
    end

    asset_full_path = Rails.root.join('app/assets/images', logical_path)
    asset_full_path.exist?
  rescue StandardError
    false
  end

  private

  def hero_image_pool
    @hero_image_pool ||= begin
      files = Dir[Rails.root.join('app/assets/images/hero_*.webp')].map { |path| File.basename(path) }
      files.select! { |file| asset_available?(file) }
      fallback = fallback_hero_image(files)
      files << fallback if fallback && !files.include?(fallback)
      files
    end
  end

  def fallback_hero_image(existing = nil)
    candidate = 'hero_01.webp'
    return candidate if (existing || hero_image_pool_without_cache).include?(candidate)

    asset_available?(candidate) ? candidate : existing&.first
  end

  def hero_image_pool_without_cache
    Dir[Rails.root.join('app/assets/images/hero_*.webp')].map { |path| File.basename(path) }
  end
end
