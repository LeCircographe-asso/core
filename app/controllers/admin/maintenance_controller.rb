class Admin::MaintenanceController < ApplicationController
  # Accès simple avec mot de passe en dur pour la maintenance
  before_action :authenticate_maintenance_admin
  skip_before_action :require_authentication

  # Désactiver CSRF pour éviter les problèmes HTTP/HTTPS
  skip_before_action :verify_authenticity_token

  # Utiliser un layout simple sans navbar admin
  layout "maintenance_admin"


  include OpeningHoursHelper

  def index
    # Système robuste: utiliser un fichier JSON simple pour la persistance
    @opening_hours = load_opening_hours
  end

  def update_hours
    Rails.logger.info "=== UPDATE HOURS DEBUG ==="
    Rails.logger.info "Session maintenance_admin: #{session[:maintenance_admin]}"
    Rails.logger.info "Params: #{params.inspect}"

    updated_hours = params.require(:opening_hours).permit(:lundi, :mardi, :mercredi, :jeudi, :vendredi, :samedi, :dimanche).to_h

    Rails.logger.info "Updated hours: #{updated_hours.inspect}"

    if valid_hours?(updated_hours)
      # Sauvegarder dans un fichier JSON simple
      Rails.logger.info "Saving hours to file..."
      save_opening_hours(updated_hours)
      Rails.logger.info "Hours saved successfully"
      redirect_to admin_maintenance_path, notice: "Horaires mis à jour avec succès!"
    else
      Rails.logger.info "Invalid hours format"
      @opening_hours = updated_hours
      flash.now[:error] = "Format invalide. Utilisez 'HH:MM - HH:MM' ou 'Fermé'"
      render :index, status: :unprocessable_entity
    end
  end

  def logout
    session[:maintenance_admin] = nil
    redirect_to admin_maintenance_path, notice: "Déconnecté avec succès"
  end

  private

  def authenticate_maintenance_admin
    # Auth simple avec mot de passe en dur pour la maintenance
    # En production, utilise une variable d'environnement
    maintenance_password = ENV["MAINTENANCE_ADMIN_PASSWORD"] || "circographe2024"

    # Si déjà authentifié, continuer
    return if session[:maintenance_admin] == true

    # Si mot de passe fourni et correct
    if params[:password].present? && params[:password] == maintenance_password
      session[:maintenance_admin] = true
      # Session plus persistante
      session[:maintenance_admin_expires] = 1.hour.from_now
      return
    end

    # Vérifier si la session a expiré
    if session[:maintenance_admin_expires] && Time.current > session[:maintenance_admin_expires]
      session[:maintenance_admin] = nil
      session[:maintenance_admin_expires] = nil
    end

    # Sinon, afficher le formulaire de login
    render :login and return
  end

  def valid_hours?(hours)
    hours.values.all? do |time|
      time.match?(/\A((?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9] - (?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9]|Fermé)\z/i)
    end
  end

  def load_opening_hours
    file_path = Rails.root.join("storage", "opening_hours.json")
    if File.exist?(file_path)
      JSON.parse(File.read(file_path)).symbolize_keys
    else
      default_opening_hours
    end
  rescue => e
    Rails.logger.error "Error loading opening hours: #{e.message}"
    default_opening_hours
  end

  def save_opening_hours(hours)
    file_path = Rails.root.join("storage", "opening_hours.json")
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, JSON.pretty_generate(hours))
  rescue => e
    Rails.logger.error "Error saving opening hours: #{e.message}"
    raise e
  end
end
