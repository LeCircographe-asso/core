# frozen_string_literal: true

class BugReport < ApplicationRecord
  include AttachedImageValidatable

  enum :status, { new_report: 0, in_progress: 1, resolved: 2, wont_fix: 3 }, default: :new_report
  enum :device_type, { mobile: "mobile", desktop: "desktop" }, validate: { allow_nil: true }
  enum :display_mode, { browser: "browser", standalone: "standalone" }, validate: { allow_nil: true }
  enum :reporter_role, { super_admin: "super_admin", admin: "admin", volunteer: "volunteer", web_visitor: "web_visitor" }, validate: { allow_nil: true }
  enum :source, { user_report: 0, automatic: 1 }, default: :user_report

  belongs_to :person, optional: true
  has_one_attached :screenshot

  validates :note, presence: true
  validate :validate_screenshot

  scope :ordered, -> { order(created_at: :desc) }

  # Exceptions volontairement exclues du reporting automatique : bruit connu (scans de bots,
  # sessions expirées) plutôt que de vrais bugs applicatifs — les inclure noierait le signal.
  AUTO_REPORT_NOISE_EXCEPTIONS = %w[
    ActionController::InvalidAuthenticityToken
    ActionController::BadRequest
    ActionController::UnknownFormat
    ActionDispatch::Http::Parameters::ParseError
  ].freeze

  AUTO_REPORT_DEDUP_WINDOW = 15.minutes

  # Point d'entrée du reporting automatique (config/initializers/automatic_bug_reporting.rb via
  # Support::AutomaticBugReportJob). Regroupe les occurrences répétées de la même erreur sur le
  # même type de page (fenêtre de 15 min) au lieu de créer une ligne par requête — un bug qui
  # boucle ne doit pas noyer la table.
  def self.record_automatic!(error_class:, message:, kind:, path: nil, backtrace: nil, user_agent: nil, person_id: nil, reporter_role: nil)
    return if AUTO_REPORT_NOISE_EXCEPTIONS.include?(error_class)

    fingerprint = Digest::SHA256.hexdigest("#{error_class}:#{normalize_path_for_fingerprint(path)}")
    existing = where(fingerprint: fingerprint).where(updated_at: AUTO_REPORT_DEDUP_WINDOW.ago..).order(updated_at: :desc).first

    if existing
      # Une erreur qui revient sur un ticket classé "réglé" prouve que ça ne l'est pas —
      # sans ça le statut n'a plus aucune valeur de signal pour l'admin (l'occurrence_count
      # grimpe en silence pendant que le ticket reste marqué "Résolu"/"Ne sera pas corrigé").
      attrs = { occurrence_count: existing.occurrence_count + 1, updated_at: Time.current }
      attrs[:status] = :new_report if existing.resolved? || existing.wont_fix?
      existing.update!(attrs)
      return existing
    end

    create!(
      note: automatic_note(kind: kind, error_class: error_class, path: path),
      page_url: path,
      user_agent: user_agent,
      person_id: person_id,
      reporter_role: reporter_role,
      source: :automatic,
      fingerprint: fingerprint,
      js_errors: [ {
        "type" => "server_#{kind}",
        "message" => message.to_s.first(500),
        "stack" => Array(backtrace).first(10).join("\n").first(2000)
      } ]
    )
  end

  def self.normalize_path_for_fingerprint(path)
    path.to_s.gsub(/\d+/, ":id")
  end
  private_class_method :normalize_path_for_fingerprint

  def self.automatic_note(kind:, error_class:, path:)
    case kind.to_sym
    when :not_found
      "Page introuvable (404) : #{path}"
    else
      "Erreur serveur (#{error_class}) : #{path}"
    end
  end
  private_class_method :automatic_note

  private

  def validate_screenshot
    validate_image_attachment(screenshot)
  end
end
