# frozen_string_literal: true

module Admin
  class ContributionsController < BaseController
    before_action :set_person

    def upgrade
      result = People::ContributionUpgrader.new(
        person: @person,
        from_contribution_id: params[:from_contribution_id] || params[:from_book_id],
        to_formula_id: params[:to_formula_id] || params[:to_plan_id],
        payment_method: params[:payment_method] || "cash",
        recorded_by_id: Current.user.id
      ).call

      if result.success?
        notice = t(".success_notice")
        if result.credit_applied.positive?
          notice += t(".credit_applied_suffix", amount: (result.credit_applied / 100.0).round(2))
        end
        redirect_to admin_user_path("person_#{@person.id}"), notice: notice
      else
        redirect_to admin_user_path("person_#{@person.id}"),
                    alert: t(".failure_alert", message: result.message)
      end
    rescue StandardError => e
      redirect_to admin_user_path("person_#{@person.id}"),
                  alert: t(".failure_alert", message: e.message)
    end

    private

    def set_person
      @person = Person.find(params[:person_id])
    end
  end
end
