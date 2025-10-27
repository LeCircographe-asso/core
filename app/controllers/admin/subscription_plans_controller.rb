module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_subscription_plan, only: [ :show, :edit, :update, :destroy ]
    before_action :set_person, only: [ :new, :create ]
    before_action :set_breadcrumbs

    def index
      @subscription_plans = SubscriptionPlan.includes(:membership_type).all.order(:duration, :price_cents)
      add_breadcrumb "Plans d'Abonnement", nil
    end

    def show
      @book_of_entries = @subscription_plan.book_of_entries.includes(:person)
      add_breadcrumb "Plan: #{@subscription_plan.name}", nil
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]

      # Vérifier que la personne peut acheter des plans d'abonnement
      unless @person&.can_buy_subscription_plans?
        flash[:alert] = "Cette personne doit avoir une adhésion Cirque pour acheter des plans d'abonnement"
        redirect_to admin_users_path
        return
      end

      # Filtrer les plans d'abonnement selon le type d'adhésion de la personne
      if @person&.current_membership&.membership_type&.circus?
        @subscription_plans = SubscriptionPlan.joins(:membership_type)
                                            .where(membership_types: { category: [ :circus_full, :circus_reduced ] })
                                            .current_versions
                                            .order(:duration, :price_cents)
      else
        @subscription_plans = []
      end

      add_breadcrumb "Nouvel abonnement", nil
    end

    def edit
      add_breadcrumb "Modifier: #{@subscription_plan.name}", nil
    end

    def update
      if @subscription_plan.update(subscription_plan_params)
        redirect_to admin_subscription_plans_path, notice: "Plan d'abonnement mis à jour avec succès !"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # Seul le super_admin peut supprimer des cotisations
      unless Current.user&.system_role == "super_admin"
        redirect_to admin_subscription_plans_path, alert: "Seul le super-admin peut supprimer des cotisations."
        return
      end

      if @subscription_plan.book_of_entries.any?
        redirect_to admin_subscription_plans_path, alert: "Impossible de supprimer ce plan car il est utilisé par des carnets d'entrées."
      else
        @subscription_plan.destroy
        redirect_to admin_subscription_plans_path, notice: "Plan d'abonnement supprimé avec succès !"
      end
    end

    def create
      @person = Person.find(subscription_params[:person_id])
      @subscription_plan = SubscriptionPlan.find(subscription_params[:subscription_plan_id])

      # Créer le carnet d'entrées (BookOfEntry)
      book_of_entry_params = {
        subscription_plan: @subscription_plan,
        sessions_remaining: @subscription_plan.sessions_count || 0,
        purchased_at: Time.current,
        status: :active
      }

      # Les packs10 n'expirent jamais, les autres plans ont une date d'expiration
      unless @subscription_plan.duration == "pack10"
        book_of_entry_params[:expires_at] = @subscription_plan.duration_days.days.from_now
      end

      book_of_entry = @person.book_of_entries.create!(book_of_entry_params)

      # Créer le paiement
      payment = Payment.create!(
        person: @person,
        recorded_by: Current.user,
        total_cents: @subscription_plan.price_cents,
        payment_method: subscription_params[:payment_method] || :cash,
        status: :success,
        notes: "Plan d'abonnement #{@subscription_plan.name}"
      )

      # Créer la ligne de paiement
      PaymentLine.create!(
        payment: payment,
        item: book_of_entry,
        amount_cents: @subscription_plan.price_cents,
        description: "Plan d'abonnement #{@subscription_plan.name}"
      )

      # Si demandé, enregistrer la présence
      if params[:record_attendance] == "true"
        attendance_date = params[:attendance_date]&.to_date || Date.current
        
        # Créer ou trouver la liste de présence du jour pour les entraînements libres
        attendance_list = AttendanceList.find_by(
          list_type: :training,
          start_date: attendance_date,
          end_date: attendance_date + 1.day
        )
        
        unless attendance_list
          attendance_list = AttendanceList.create!(
            list_type: :training,
            start_date: attendance_date,
            end_date: attendance_date + 1.day,
            name: "Entraînement libre #{attendance_date.strftime('%d/%m/%Y')}",
            status: :open
          )
        end
        
        Attendance.create!(
          person: @person,
          date: attendance_date,
          book_of_entry: book_of_entry,
          attendance_list: attendance_list
        )
        
        book_of_entry&.use_session!
        
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("attendance-frame-#{@person.id}", 
                partial: "admin/users/attendance_success", 
                locals: { person: @person, result: OpenStruct.new(message: "Cotisation payée et présence enregistrée") }),
              turbo_stream.update("flash", 
                partial: "shared/flash", 
                locals: { notice: "Cotisation payée et présence enregistrée avec succès" })
            ]
          end
          format.html do
            redirect_to admin_user_path("person_#{@person.id}"), notice: "Cotisation achetée avec succès !"
          end
        end
      else
        # Comportement existant
        redirect_to admin_user_path("person_#{@person.id}"), notice: "Cotisation achetée avec succès !"
      end
    rescue => e
      flash[:alert] = "Erreur lors de l'achat du plan: #{e.message}"
      redirect_to new_admin_subscription_plan_path(person_id: @person.id)
    end

    private

    def set_subscription_plan
      @subscription_plan = SubscriptionPlan.find(params[:id])
    end

    def set_person
      @person = Person.find(params[:person_id]) if params[:person_id]
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_dashboard_index_path
      add_breadcrumb "Plans d'Abonnement", admin_subscription_plans_path
    end

    def subscription_params
      params.require(:subscription_plan).permit(:person_id, :subscription_plan_id, :payment_method)
    end

    def subscription_plan_params
      params.require(:subscription_plan).permit(:name, :duration, :price_cents, :description, :membership_type_id, :sessions_count, :validity_days)
    end
  end
end
