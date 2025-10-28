module Admin
  class PaymentsController < BaseController
    # Remove the before_action since we don't need the dashboard breadcrumb
    # before_action :set_breadcrumbs

    def index
      # Start with all payments with eager loading (nouveau modèle)
      @payments = PaymentQuery.with_person_and_recorded_by

      # Filter by person if person_id is provided
      @person = Person.find_by(id: params[:person_id])
      @payments = PaymentQuery.by_person(@person.id) if @person

      # Compatibilité avec l'ancien système (user_id)
      @user = User.find_by(id: params[:user_id])
      @payments = PaymentQuery.by_user(@user.id) if @user

      # Apply filters if provided
      @payments = PaymentQuery.by_status(params[:status]) if params[:status].present?

      # Filter by date range if provided
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        @payments = PaymentQuery.by_date_range(start_date, end_date)
      end

      # Apply sorting (default to newest first)
      sort_column = params[:sort] || "payment_date"
      sort_direction = params[:direction] || "desc"
      @payments = @payments.order("#{sort_column} #{sort_direction}")

      # Ensure we're using the filtered payment set for calculations
      @total_amount = PaymentQuery.total_amount
      @total_donation = PaymentQuery.total_donation

      # Handle loading a specific payment details
      if params[:id].present?
        @payment = Payment.includes(order: { product_orders: { product: :price_entries } }).find_by(id: params[:id])
        if @payment
          @order = @payment.order
          @total_donation = @order&.donation
        end
      end

      # Set breadcrumb
      if @user
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb @user.full_name.present? ? @user.full_name : "Utilisateur ##{@user.id}", admin_user_path(@user)
        add_breadcrumb "Historique des paiements", nil
      else
        add_breadcrumb "Historique des paiements", nil
      end
    end

    def new
      @payment = Payment.new

      # Set breadcrumb
      if params[:user_id].present?
        @user = User.find_by(id: params[:user_id])
        if @user
          add_breadcrumb "Liste d'adhérents", admin_users_path
          add_breadcrumb @user.full_name.present? ? @user.full_name : "Utilisateur ##{@user.id}", admin_user_path(@user)
          add_breadcrumb "Historique des paiements", admin_payments_path(user_id: @user.id)
          add_breadcrumb "Nouveau paiement", nil
        end
      else
        add_breadcrumb "Historique des paiements", admin_payments_path
        add_breadcrumb "Nouveau paiement", nil
      end
    end

    def show
      @payments = Payment.includes(:user, order: { product_orders: { product: :price_entries } })
      @payment = Payment.includes(:user, order: { product_orders: { product: :price_entries } }).find(params[:id])
      @order = @payment.order

      @total_amount = @order.product_orders.sum do |product_order|
        product_order.product.price_entries.order(created_at: :desc).first&.price_catalog&.price.to_i
      end

      @total_donation = @order.donation
      @total_payment = (@total_amount || 0) + (@total_donation || 0)

      # Set breadcrumb
      if @payment.user.present?
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb @payment.user.full_name.present? ? @payment.user.full_name : "Utilisateur ##{@payment.user.id}", admin_user_path(@payment.user)
        add_breadcrumb "Historique des paiements", admin_payments_path(user_id: @payment.user.id)
        add_breadcrumb "Détail du paiement ##{@payment.id}", nil
      else
        add_breadcrumb "Historique des paiements", admin_payments_path
        add_breadcrumb "Détail du paiement ##{@payment.id}", nil
      end
    end

    def create
      begin
        person = Person.find(payment_params[:person_id])
        
        # Créer le paiement directement
        payment = person.payments.create!(
          total_cents: payment_params[:total_cents],
          payment_method: payment_params[:payment_method] || "cash",
          status: :success,
          recorded_by: Current.user,
          notes: payment_params[:notes]
        )

        redirect_to admin_payment_path(payment), notice: "Paiement créé avec succès"
      rescue => e
        redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement: #{e.message}"
      end
    end

    def update
      @payment = Payment.find(params[:id])

      if @payment.update(payment_params)
        redirect_to admin_payment_path(@payment), notice: "Mise à jour réussie"
      else
        redirect_to admin_payment_path(@payment), alert: "Échec de la mise à jour"
      end
    end

    # Add destroy method with soft deletion support
    def destroy
      @payment = Payment.find(params[:id])

      # Instead of actually deleting, mark as cancelled
      if @payment.update(status: :cancel)
        # Clear Rails cache to ensure payment totals are recalculated
        Rails.cache.delete("total_successful_payments")
        Rails.cache.delete("total_donations")

        # Clear view fragment caches
        expire_fragment(/payments_summary/)
        expire_fragment(/payments_total_amount/)

        redirect_to admin_payments_path, notice: "Paiement annulé avec succès"
      else
        redirect_to admin_payments_path, alert: "Échec de l'annulation du paiement"
      end
    end

    private

    def payment_params
      # Nouveau modèle Person-Based
      params.require(:payment).permit(
        :person_id, :recorded_by_id, :total_cents, :payment_method, :status, :notes,
        # Compatibilité avec l'ancien modèle
        :payment_id, :payment_date, :payment_amount, :payment_type, :user_id, :order_id, :donation, :total_payment
      )
    end

    # Remove the set_breadcrumbs method since we don't need the dashboard breadcrumb
    # def set_breadcrumbs
    #   add_breadcrumb "Dashboard", admin_dashboard_index_path
    # end
  end
end
