# frozen_string_literal: true

module Admin
  class DonationsController < BaseController
    def create
      if params[:person_id].present?
        @person = Person.find(params[:person_id])
        @user = @person.user
      else
        @user = User.find(params[:user_id])
        @person = @user.person
      end

      begin
        amount_cents = (payment_params[:payment_amount].to_f * 100).to_i

        result = People::PaymentCreator.new(
          person: @person,
          amount_cents: amount_cents,
          payment_method: "cash",
          recorded_by_id: Current.user&.id,
          item_type: "Donation",
          item_id: @person.id,
          description: "Donation",
          notes: "Donation"
        ).call

        if result.success?
          redirect_to admin_payment_path(result.payment), notice: t(".recorded")
        else
          flash[:alert] = "Erreur lors de la création de la donation: #{result.message}"
          render :new
        end
      rescue StandardError => e
        flash[:alert] = "Erreur lors de la création de la donation: #{e.message}"
        render :new
      end
    end

    private

    def payment_params
      params.expect(payment: %i[payment_amount payment_date payment_type status donation total_payment user_id person_id])
    end
  end
end
