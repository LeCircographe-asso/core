# frozen_string_literal: true

module Admin
  class OpeningHoursController < BaseController
    before_action :set_opening_hours, only: %i[show edit]
    before_action :set_breadcrumbs
    include OpeningHoursHelper

    def show
      add_breadcrumb I18n.t("breadcrumbs.admin.opening_hours.title"), nil
    end

    def edit
      add_breadcrumb I18n.t("breadcrumbs.admin.opening_hours.title"), admin_opening_hours_path
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    def update
      updated_hours = build_schedule_params
      OpeningHour.replace_schedule!(schedule_hash: updated_hours, updated_by_user: current_user)
      redirect_to admin_opening_hours_path, notice: t(".success")
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      @opening_hours = updated_hours || current_opening_hours
      @error_message = e.record&.errors&.full_messages&.to_sentence || e.message
      render :edit, status: :unprocessable_content
    end

    private

    def set_opening_hours
      @opening_hours = current_opening_hours
    end

    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end

    def build_schedule_params
      OpeningHour::DAYS.keys.each_with_object({}) do |day, updated_hours|
        day_name = day.to_s

        updated_hours[day_name] =
          if params["closed_#{day_name}"] == "1"
            "Fermé"
          else
            open_hour = params["open_hour_#{day_name}"].to_i
            open_minute = params["open_minute_#{day_name}"].to_i
            close_hour = params["close_hour_#{day_name}"].to_i
            close_minute = params["close_minute_#{day_name}"].to_i

            "#{open_hour.to_s.rjust(2, '0')}:#{open_minute.to_s.rjust(2, '0')} - #{close_hour.to_s.rjust(2, '0')}:#{close_minute.to_s.rjust(2, '0')}"
          end
      end
    end
  end
end
