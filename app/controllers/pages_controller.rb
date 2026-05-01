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
      @faqs = contact_faq_entries
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
    [
      { question: "Comment adhérer au Circographe ?", answer: "Passe sur un créneau d'ouverture : on remplit la fiche ensemble et on t'explique le fonctionnement." },
      { question: "Puis-je réserver un créneau de résidence ?", answer: "Oui, écris-nous via la catégorie 'Résidence'. Nous te recontacterons avec les disponibilités et modalités." },
      { question: "Le lieu est-il accessible aux débutant·es ?", answer: "Les entraînements libres sont destinés aux personnes autonomes. Pour débuter, on recommande une école partenaire : contacte-nous pour des conseils." },
      { question: "Proposez-vous des prestations ou des partenariats ?", answer: "Oui, nous travaillons avec des structures culturelles, établissements scolaires et entreprises. Sélectionne la catégorie 'Partenariat' pour en discuter." }
    ]
  end

  def adhesion_faq_entries
    [
      { question: "Puis-je adhérer en ligne ?", answer: "L'inscription se fait uniquement sur place afin de te présenter le lieu et les règles d'autogestion." },
      { question: "Quels moyens de paiement acceptez-vous ?", answer: "Carte bancaire et espèces, sur place." },
      { question: "Faut-il être autonome pour les entraînements libres ?", answer: "Oui, les créneaux libres s'adressent aux pratiquant·es autonomes. Pour débuter, on peut te recommander des écoles partenaires." },
      { question: "Puis-je proposer un atelier ou un événement ?", answer: "Tout est possible ! Passe nous voir avec ton idée, on regardera ensemble comment l'inscrire dans la programmation." }
    ]
  end

  def general_faq_entries
    [
      { question: "Où se situe le Circographe ?", answer: "Au 97 bis boulevard de Suisse, 31200 Toulouse. Consulte la page Contact pour la carte et l’accès en bus (ligne 15)." },
      { question: "Quels sont les horaires d'ouverture ?", answer: "Les créneaux publics évoluent chaque saison ; on les met à jour sur les pages Accueil, Adhérer et Contact. Pense à vérifier avant de te déplacer." },
      { question: "Comment soutenir financièrement le projet ?", answer: "En adhérant, en faisant un don ponctuel, ou en devenant partenaire. Écris-nous pour en discuter." },
      { question: "J'ai une question administrative, qui contacter ?", answer: "Utilise le formulaire de contact (catégorie 'Question générale') ou écris à contact@lecircographe.fr ; l'équipe bénévole te répondra rapidement." }
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
