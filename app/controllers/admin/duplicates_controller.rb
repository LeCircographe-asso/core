# frozen_string_literal: true

module Admin
  # Version volontairement minimale : détecte via Admin::HealthReport (déjà en place),
  # fusionne via People::AccountMerger (déjà en place, déjà utilisé par le flux de
  # réclamation de compte). Sert de point de départ avant l'import Excel/Sheets —
  # les doublons vont devenir courants une fois l'import branché, ce contrôleur doit
  # déjà exister et fonctionner avant ce jour-là.
  class DuplicatesController < BaseController
    before_action :require_admin_rights

    def index
      report = Admin::HealthReport.new.call

      @duplicate_people_by_email_groups = report.duplicate_people_by_email.group_by { |person| person.email.to_s.downcase }
      @duplicate_people_by_phone_groups = report.duplicate_people_by_phone.group_by { |person| person.phone.to_s }

      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
      add_breadcrumb I18n.t("admin.duplicates.breadcrumb"), nil
    end

    def merge
      target_person_id = params[:target_person_id]
      source_person_ids = Array(params[:source_person_ids]).reject(&:blank?)

      if target_person_id.blank? || source_person_ids.empty?
        redirect_to admin_duplicates_path, alert: t(".missing_selection_alert")
        return
      end

      results = source_person_ids.map do |source_person_id|
        People::AccountMerger.new(
          source_person_id: source_person_id,
          target_person_id: target_person_id,
          actor_id: Current.user.id,
          merge_type: "admin_duplicates"
        ).call
      end

      if results.all?(&:success?)
        redirect_to admin_duplicates_path, notice: t(".success_notice", count: results.size)
      else
        failure = results.find { |r| !r.success? }
        redirect_to admin_duplicates_path, alert: t(".failure_alert", message: failure.message)
      end
    end
  end
end
