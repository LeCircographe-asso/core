module Admin
  module Users
    # Admin::Users::PaymentsController handles payment management
    # for specific users/persons. This controller is responsible for:
    # - Creating new payments
    # - Processing payments
    # - Managing payment-related operations
    class PaymentsController < BaseController
      before_action :set_person
      before_action :set_breadcrumbs

      # GET /admin/users/person_1/payments
      def index
        @payments = @person.payments.includes(:payment_lines, :recorded_by)
                          .order(created_at: :desc)
                          .page(params[:page])
      end

      # GET /admin/users/person_1/payments/new
      def new
        @payment = @person.payments.build
        @payment.recorded_by = Current.user
        @membership_types = MembershipType.all
        @subscription_plans = SubscriptionPlan.all
      end

      # POST /admin/users/person_1/payments
    def create
      begin
        # Créer le paiement directement via le modèle Person
        payment = @person.payments.create!(
          total_cents: payment_params[:total_cents],
          payment_method: payment_params[:payment_method] || "cash",
          status: :success,
          recorded_by: Current.user,
          notes: payment_params[:notes]
        )

        # Ajouter les lignes de paiement si spécifiées
        if params[:payment_lines].present?
          params[:payment_lines].each do |line_params|
            payment.payment_lines.create!(
              item_type: line_params[:item_type],
              item_id: line_params[:item_id],
              amount_cents: line_params[:amount_cents],
              description: line_params[:description]
            )
          end
        end

        redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement créé avec succès"
      rescue => e
        @membership_types = MembershipType.all
        @subscription_plans = SubscriptionPlan.all
        flash.now[:alert] = "Erreur lors de la création du paiement: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    end

      # GET /admin/users/person_1/payments/1
      def show
        @payment = @person.payments.find(params[:id])
      end

      # PATCH /admin/users/person_1/payments/1
      def update
        @payment = @person.payments.find(params[:id])

        if @payment.update(payment_params)
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement mis à jour avec succès"
        else
          redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la mise à jour: #{@payment.errors.full_messages.join(', ')}"
        end
      end

      # DELETE /admin/users/person_1/payments/1
      def destroy
        @payment = @person.payments.find(params[:id])

        if @payment.destroy
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement supprimé avec succès"
        else
          redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la suppression du paiement"
        end
      end

      # POST /admin/users/person_1/payments/1/process
    def process_payment
      @payment = @person.payments.find(params[:id])
      
      begin
        # Traiter le paiement (marquer comme success s'il ne l'est pas déjà)
        @payment.update!(status: :success) if @payment.pending?
        
        redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement traité avec succès"
      rescue => e
        redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors du traitement: #{e.message}"
      end
    end

      private

      def set_person
        person_id = params[:person_id].to_s.gsub("person_", "")
        @person = Person.find(person_id)
      end

      def set_breadcrumbs
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb @person.full_name, admin_user_path("person_#{@person.id}")
        add_breadcrumb "Gestion des paiements", nil
      end

      def payment_params
        params.require(:payment).permit(
          :total_cents,
          :payment_method,
          :status,
          :notes,
          :recorded_by_id
        )
      end
    end
  end
end
