module Admin
  class SubscriptionsController < BaseController
    before_action :set_person

    def upgrade
      result = @person.upgrade_subscription!(
        from_book_id: params[:from_book_id],
        to_plan_id: params[:to_plan_id],
        payment_method: params[:payment_method] || "cash",
        recorded_by: Current.user
      )

      if result[:payment]
        redirect_to admin_user_path("person_#{@person.id}"),
                    notice: "Cotisation upgradée. Crédit: #{result[:credit_applied]/100.0}€"
      else
        redirect_to admin_user_path("person_#{@person.id}"),
                    alert: "Erreur upgrade"
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
