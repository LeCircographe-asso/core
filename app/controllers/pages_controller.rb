# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :require_authentication
  include NotepadHelper
  include OpeningHoursHelper

  layout "application"

  # Matches app/views/pages/*.html.erb (slug must not be user-controlled for render path)
  ALLOWED_PAGE_IDS = %w[
    about association become_member blog_newsletter circus_details contact_us faq gallery
    graphic_arts_details news newsletter_unsubscribe_success privacy_policy terms
  ].freeze

  def show
    redirect_mapping = {
      "circus_details" => { page: "association", anchor: "le-cirque" },
      "graphic_arts_details" => { page: "association", anchor: "les-arts-graphiques" }
    }

    if (target = redirect_mapping[params[:id]])
      return redirect_to page_path(target[:page], anchor: target[:anchor]), status: :moved_permanently
    end

    @opening_hours = Rails.cache.fetch("opening_hours") || default_opening_hours
    @notepad = Rails.cache.fetch("notepad") || default_notepad
    @blogs = Blog.order(created_at: :desc).limit(3)

    if params[:id] == "news"
      @upcoming_events = Event.upcoming.by_date.limit(6)
      @past_events = Event.past.order(date: :desc).limit(6)
      @latest_posts = Blog.order(created_at: :desc).limit(6)
    end

    if params[:id] == "contact_us"
      @contact = {}
    end

    @adhesion_faqs = adhesion_faq_entries if params[:id] == "become_member"

    if params[:id] == "faq"
      @contact_faqs = contact_faq_entries
      @adhesion_faqs = adhesion_faq_entries
      @general_faqs = general_faq_entries
    end

    if params[:id] == "about"
      @board_members = load_yaml_content("board_members")
      @partners = load_yaml_content("partners")
    end

    page_id = params[:id].to_s
    raise ActiveRecord::RecordNotFound unless ALLOWED_PAGE_IDS.include?(page_id)

    render template: "pages/#{page_id}"
  end

  private

  def contact_faq_entries
    cf = page_path("contact_us", anchor: "contact-form")
    lc = "text-[#5836A5] underline hover:text-[#412886]"
    [
      {
        question: "Demander un temps d’accueil en création",
        answer_html: helpers.safe_join([
          "Écris-nous avec le ",
          helpers.link_to("formulaire Contact", cf, class: lc),
          ", catégorie « Temps d’accueil en création » — on te répond sur les dispo et le cadre."
        ])
      },
      {
        question: "Partenariat, atelier, événement ou projet avec le lieu",
        answer_html: helpers.safe_join([
          "Le plus simple : passer lors d’un créneau d’ouverture avec ton idée. Tu peux aussi utiliser le ",
          helpers.link_to("formulaire Contact", cf, class: lc),
          " (Partenariat ou Question générale). Les bénévoles t’orientent."
        ])
      }
    ]
  end

  def adhesion_faq_entries
    cf = page_path("contact_us", anchor: "contact-form")
    lc = "text-[#5836A5] underline hover:text-[#412886]"
    [
      {
        question: "Comment adhérer ?",
        answer: "Sur place, lors d’un créneau d’accueil : visite du lieu, fiche d’adhésion et explication de l’autogestion. Pas d’inscription en ligne — on fait ça ensemble au lieu pour que chacun·e parte avec les mêmes repères."
      },
      {
        question: "Paiement adhésion ou cotisation",
        answer: "Carte bancaire ou espèces à l’accueil, avec les bénévoles."
      },
      {
        question: "Je débute : les entraînements libres me concernent ?",
        answer_html: helpers.safe_join([
          "Les créneaux libres cirque sont pour des pratiquant·es autonomes en sécurité. Pour apprendre les bases, une école partenaire ; pour une orientation, ",
          helpers.link_to("écris-nous", cf, class: lc),
          " en Question générale."
        ])
      }
    ]
  end

  def general_faq_entries
    cf = page_path("contact_us", anchor: "contact-form")
    bm = page_path("become_member", anchor: "tarifs")
    lc = "text-[#5836A5] underline hover:text-[#412886]"
    [
      {
        question: "Adresse et accès",
        answer_html: helpers.safe_join([
          "97 bis boulevard de Suisse, 31200 Toulouse. ",
          helpers.link_to("Plan et bus (ligne 15)", page_path("contact_us", anchor: "map"), class: lc),
          "."
        ])
      },
      {
        question: "Horaires",
        answer: "Les créneaux publics bougent selon la saison et les bénévoles. À jour sur l’accueil, la page Adhérer et la page Contact — jette un œil avant de venir."
      },
      {
        question: "Soutenir le lieu ou une question administrative",
        answer_html: helpers.safe_join([
          "Adhérer, cotisation, don : ",
          helpers.link_to("page Adhérer", bm, class: lc),
          ". Pour un partenariat, un don hors cadre ou une demande administrative : ",
          helpers.link_to("formulaire Contact", cf, class: lc),
          " (Question générale ou Partenariat)."
        ])
      }
    ]
  end

  def load_yaml_content(key)
    path = Rails.root.join("config/content/#{key}.yml")
    raw = YAML.load_file(path)
    Array(raw).each_with_index.map { |entry, idx| entry.to_h.deep_symbolize_keys.merge(_idx: idx) }
                              .sort_by { |entry| [ entry[:display_order] || Float::INFINITY, entry[:_idx] ] }
                              .map { |entry| entry.except(:_idx) }
  rescue Errno::ENOENT, Psych::SyntaxError => e
    Rails.logger.error("Content load failed: #{e.message}")
    []
  end
end
