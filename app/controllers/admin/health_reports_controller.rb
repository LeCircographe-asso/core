# frozen_string_literal: true

module Admin
  class HealthReportsController < BaseController
    before_action :set_breadcrumbs

    def index
      report = Admin::HealthReport.new.call

      @users_without_person = report.users_without_person
      @users_without_person_count = report.users_without_person_count
      @people_without_user = report.people_without_user
      @people_without_user_count = report.people_without_user_count
      @payments_without_person = report.payments_without_person
      @payments_without_person_count = report.payments_without_person_count
      @duplicate_people_by_email_count = report.duplicate_people_by_email_count
      @duplicate_people_by_phone_count = report.duplicate_people_by_phone_count
      @duplicate_people_by_email_groups = report.duplicate_people_by_email.group_by { |person| person.email.to_s.downcase }
      @duplicate_people_by_phone_groups = report.duplicate_people_by_phone.group_by { |person| person.phone.to_s }
      @list_limit = Admin::HealthReport::MAX_LIST

      add_breadcrumb "Rapport d'intégrité", nil
    end

    private

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_dashboard_index_path
    end
  end
end
