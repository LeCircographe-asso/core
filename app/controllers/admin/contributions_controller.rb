# frozen_string_literal: true

module Admin
  class ContributionsController < BaseController
    before_action :set_person

    def upgrade
      result = build_contribution_upgrader.call

      if result.success?
        redirect_to admin_person_path(@person), notice: upgrade_notice_for(result)
      else
        redirect_to admin_person_path(@person), alert: upgrade_failure_message(result.message)
      end
    rescue StandardError => e
      redirect_to admin_person_path(@person), alert: upgrade_failure_message(e.message)
    end

    private

    def set_person
      @person = Person.find(params[:person_id])
    end

    def admin_person_path(person)
      admin_member_path(person)
    end

    def build_contribution_upgrader
      People::ContributionUpgrader.new(
        person: @person,
        from_contribution_id: source_contribution_id,
        to_formula_id: target_formula_id,
        payment_method: params[:payment_method].presence || "cash",
        recorded_by_id: Current.user.id,
        offer_reason: params[:offer_reason]
      )
    end

    def source_contribution_id
      params[:from_contribution_id].presence || params[:from_book_id]
    end

    def target_formula_id
      params[:to_formula_id].presence || params[:to_plan_id]
    end

    def upgrade_notice_for(result)
      return t(".success_notice") unless result.credit_applied.positive?

      t(".success_notice") + t(".credit_applied_suffix", amount: (result.credit_applied / 100.0).round(2))
    end

    def upgrade_failure_message(message)
      t(".failure_alert", message: message)
    end
  end
end
