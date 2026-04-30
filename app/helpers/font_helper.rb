# frozen_string_literal: true

# Helper pour la gestion des fonts dans l'application
module FontHelper
  # Fonts disponibles dans l'application
  AVAILABLE_FONTS = {
    "inter" => "Inter",
    "circographe" => "Circographe",
    "rough-typewriter" => "Rough Typewriter",
    "jetbrains" => "JetBrains Mono",

    "dyslexic" => "OpenDyslexic",
    "roboto" => "Roboto"
  }.freeze

  # Classes CSS pour les fonts
  FONT_CLASSES = {
    "inter" => "font-inter",
    "circographe" => "font-circographe",
    "rough-typewriter" => "font-rough-typewriter",
    "jetbrains" => "font-jetbrains",
    "dyslexic" => "font-dyslexic",
    "roboto" => "font-roboto"
  }.freeze

  # Typography scale classes
  TYPOGRAPHY_CLASSES = {
    "display" => "text-display",
    "heading" => "text-heading",
    "body" => "text-body",
    "code" => "text-code"
  }.freeze

  # Retourne la classe CSS pour une font donnée
  def font_class(font_name)
    FONT_CLASSES[font_name.to_s] || "font-inter"
  end

  # Retourne la classe CSS pour un style de typographie
  def typography_class(style)
    TYPOGRAPHY_CLASSES[style.to_s] || "text-body"
  end

  # Retourne le nom de la font pour l'affichage
  def font_display_name(font_name)
    AVAILABLE_FONTS[font_name.to_s] || "Inter"
  end

  # Génère les options pour un select de fonts
  def font_options_for_select
    AVAILABLE_FONTS.map { |key, value| [ value, key ] }
  end

  # Retourne la font par défaut selon le contexte
  def default_font_for_context(context = :body)
    case context
    when :display
      "font-circographe"
    when :heading
      "font-inter"
    when :code
      "font-jetbrains"
    when :body
      "font-inter"
    else
      "font-inter"
    end
  end

  # Retourne la font de l'utilisateur connecté ou la font par défaut
  def user_font_class
    return "font-dyslexic" if current_user&.dyslexic_font?

    "font-inter"
  end

  # Retourne les classes CSS pour le body selon l'utilisateur
  def body_font_classes
    classes = [ "font-inter" ]
    classes << "font-dyslexic" if current_user&.dyslexic_font?
    classes.join(" ")
  end

  # Retourne les métadonnées des fonts pour le SEO
  def font_meta_tags
    content_for :head do
      concat stylesheet_link_tag "fonts", 'data-turbo-track': "reload"
    end
  end

  # Retourne les classes CSS pour les composants Flowbite avec fonts
  def flowbite_font_classes(component = :default)
    base_classes = case component
    when :button
                     "font-inter font-medium"
    when :input
                     "font-inter"
    when :card
                     "font-inter"
    when :modal
                     "font-inter"
    else
                     "font-inter"
    end

    base_classes += " font-dyslexic" if current_user&.dyslexic_font?
    base_classes
  end
end
