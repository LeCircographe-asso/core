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
        # Calculer le total si plusieurs lignes
        total_cents = if params[:payment_lines].present? && params[:payment_lines].any?
          params[:payment_lines].sum { |line| line[:amount_cents].to_i }
        else
          payment_params[:total_cents].to_i
        end

        # Utiliser PaymentCreatorWithLines pour paiements multiples, PaymentCreator pour paiement simple
        if params[:payment_lines].present? && params[:payment_lines].length > 1
          creator = PaymentManagement::PaymentCreatorWithLines.new(
            person_id: @person.id,
            total_cents: total_cents,
            payment_method: payment_params[:payment_method] || "cash",
            recorded_by_id: Current.user.id,
            payment_lines: params[:payment_lines],
            notes: payment_params[:notes]
          )
        else
          # Paiement simple (1 ligne ou donation)
          first_line = params[:payment_lines]&.first
          creator = PaymentManagement::PaymentCreator.new(
            person_id: @person.id,
            amount_cents: total_cents,
            payment_method: payment_params[:payment_method] || "cash",
            recorded_by_id: Current.user.id,
            item_type: first_line ? first_line[:item_type] : "Donation",
            item_id: first_line ? first_line[:item_id] : @person.id,
            description: first_line ? first_line[:description] : "Paiement",
            notes: payment_params[:notes]
          )
        end

        result = creator.call

        if result.success?
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement créé avec succès"
        else
          @membership_types = MembershipType.all
          @subscription_plans = SubscriptionPlan.all
          flash.now[:alert] = "Erreur lors de la création du paiement: #{result.message}"
          render :new, status: :unprocessable_entity
        end
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

        # Utiliser le service PaymentManagement::PaymentUpdater pour cohérence
        total_cents = payment_params[:total_cents]
        total_cents = (total_cents.to_f * 100).to_i if total_cents.present?

        updater = PaymentManagement::PaymentUpdater.new(
          payment_id: @payment.id,
          total_cents: total_cents || @payment.total_cents,
          payment_method: payment_params[:payment_method] || @payment.payment_method,
          status: payment_params[:status] || @payment.status,
          notes: payment_params[:notes] || @payment.notes,
          updated_by_id: Current.user.id
        )

        result = updater.call

        if result.success?
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement mis à jour avec succès"
        else
          redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la mise à jour: #{result.message}"
        end
      end

      # DELETE /admin/users/person_1/payments/1
      def destroy
        @payment = @person.payments.find(params[:id])

        # Utiliser le service PaymentManagement::PaymentDeleter pour cohérence
        deleter = PaymentManagement::PaymentDeleter.new(
          payment_id: @payment.id,
          deleted_by_id: Current.user.id,
          reason: "Suppression via interface admin"
        )

        result = deleter.call

        if result.success?
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement supprimé avec succès"
        else
          redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la suppression: #{result.message}"
        end
      end

    # POST /admin/users/person_1/payments/1/process
    def process_payment
      @payment = @person.payments.find(params[:id])

      begin
        # Utiliser le service PaymentManagement::PaymentUpdater pour traiter le paiement
        if @payment.pending?
          updater = PaymentManagement::PaymentUpdater.new(
            payment_id: @payment.id,
            status: "success",
            updated_by_id: Current.user.id
          )

          result = updater.call

          if result.success?
            redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement traité avec succès"
          else
            redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors du traitement: #{result.message}"
          end
        else
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Paiement déjà traité"
        end
      rescue => e
        redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors du traitement: #{e.message}"
      end
    end

      private

      def set_person
        identifier = params[:person_id].presence || params[:user_id].presence
        raise ActiveRecord::RecordNotFound, "person identifier missing" if identifier.blank?

        if identifier.to_s.start_with?("person_")
          person_id = identifier.to_s.delete_prefix("person_")
          @person = Person.find(person_id)
        else
          user = User.find(identifier)
          @person = user.person || Person.find(identifier)
        end
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
