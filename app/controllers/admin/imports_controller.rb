# frozen_string_literal: true

module Admin
  class ImportsController < BaseController
    before_action :authorize_administer!, only: %i[index create]

    def index
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
      add_breadcrumb "Import/Export", nil
    end

    # Répond avec un fragment HTML brut (pas de layout) : consommé par le Stimulus
    # controller via fetch() pour remplacer le contenu de la modal sans navigation.
    def create
      file = params[:csv_file]
      if file.blank?
        render partial: "admin/imports/error_panel", locals: { message: t(".file_required") },
               layout: false, status: :bad_request
        return
      end

      csv_content = file.read.force_encoding("UTF-8")
      result = Imports::MemberImportService.new(csv_content: csv_content).call

      render partial: "admin/imports/result_panel", locals: { result: result }, layout: false
    rescue StandardError => e
      Rails.logger.error("[ImportsController] Error: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      render partial: "admin/imports/error_panel", locals: { message: "Erreur : #{e.message}" },
             layout: false, status: :internal_server_error
    end

    private

    def authorize_administer!
      redirect_to admin_dashboard_index_path, alert: t(".access_denied") unless current_user.can_administer?
    end
  end
end
