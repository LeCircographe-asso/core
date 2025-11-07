module Admin
  class SubscriptionsController < BaseController
    before_action :set_person

    def upgrade
      upgrader = SubscriptionManagement::SubscriptionUpgrader.new(
        person: @person,
        from_book_id: params[:from_book_id],
        to_plan_id: params[:to_plan_id],
        payment_method: params[:payment_method] || "cash",
        recorded_by_id: Current.user.id
      )

      result = upgrader.call

      if result.success?
        credit_message = result.credit_applied.positive? ? " Crédit appliqué: #{result.credit_applied / 100.0}€" : ""
        redirect_to admin_user_path("person_#{@person.id}"),
                    notice: "Cotisation upgradée avec succès.#{credit_message}"
      else
        redirect_to admin_user_path("person_#{@person.id}"),
                    alert: "Erreur lors de l'upgrade: #{result.message}"
      end
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"),
                  alert: "Erreur lors de l'upgrade: #{e.message}"
    end

    private

    def set_person
      @person = Person.find(params[:person_id])
    end
  end
end
