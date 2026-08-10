# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :require_authentication
  include NotepadHelper
  include OpeningHoursHelper

  layout "application"

  # Matches app/views/pages/*.html.erb (slug must not be user-controlled for render path)
  ALLOWED_PAGE_IDS = %w[
    about association become_member blog_newsletter circus_details contact_us faq gallery
    graphic_arts_details news newsletter_unsubscribe_success privacy_policy terms white_page
  ].freeze

  def show
    redirect_mapping = {
      "circus_details" => { page: "association", anchor: "le-cirque" },
      "graphic_arts_details" => { page: "association", anchor: "les-arts-graphiques" }
    }

    if (target = redirect_mapping[params[:id]])
      return redirect_to page_path(target[:page], anchor: target[:anchor]), status: :moved_permanently
    end

    @opening_hours = current_opening_hours
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

    @avant_visite_faqs = Faq.by_label("avant_visite") if params[:id] == "become_member"

    if params[:id] == "faq"
      @contact_faqs  = Faq.by_label("contact")
      @adhesion_faqs = Faq.by_label("adhesion")
      @general_faqs  = Faq.by_label("general")
    end

    if params[:id] == "about"
      @board_members = load_yaml_content("board_members")
      @partners = load_yaml_content("partners")
    end

    # Mélangé à chaque chargement (comme l'ancien pool statique) — l'admin
    # gère quelles photos existent, pas leur ordre d'affichage.
    @gallery_photos = GalleryPhoto.all.to_a.sample(18) if params[:id] == "gallery"

    page_id = params[:id].to_s
    raise ActiveRecord::RecordNotFound unless ALLOWED_PAGE_IDS.include?(page_id)

    render template: "pages/#{page_id}"
  end

  private

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
