# frozen_string_literal: true

module Admin
  class ExceptionalClosuresController < BaseController
    def update
      closure = ExceptionalClosure.current

      if params[:active] == "1"
        closure.update!(active: true, label: params[:label].presence, ends_on: params[:ends_on].presence, updated_by_user: current_user)
      else
        closure.update!(active: false, updated_by_user: current_user)
      end

      redirect_to admin_opening_hours_path, notice: t(".success")
    end
  end
end
