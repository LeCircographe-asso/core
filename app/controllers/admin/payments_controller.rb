module Admin
  class PaymentsController < BaseController
    before_action :set_breadcrumbs

    def index
      # Start with all payments with eager loading
      @payments = Payment.includes(:user, order: { product_orders: { product: :price_entries } })

      # Filter by user if user_id is provided
      @user = User.find_by(id: params[:user_id])
      @payments = @user.payments.includes(:user, order: { product_orders: { product: :price_entries } }) if @user

      # Apply filters if provided
      @payments = @payments.where(status: params[:status]) if params[:status].present?

      # Filter by date range if provided
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        @payments = @payments.where(payment_date: start_date.beginning_of_day..end_date.end_of_day)
      end

      # Apply sorting (default to newest first)
      sort_column = params[:sort] || "payment_date"
      sort_direction = params[:direction] || "desc"
      @payments = @payments.order("#{sort_column} #{sort_direction}")

      # Calculate total amount for display
      @total_amount = @payments.where(status: :success).sum(:payment_amount)
      @total_donation = @payments.where(status: :success).sum(:donation)

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
      # Remove debug output
      @user = User.find(payment_params[:user_id])
      @payment = Payment.new(payment_params)

      if @payment.save
        redirect_to admin_payment_path(@payment), notice: "Cotisation prise en compte"
      else
        redirect_to admin_product_order_path, alert: "Erreur lors de la création du paiement"
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
        # Expire fragment caches to force a refresh
        expire_fragment("payments_total_amount")
        expire_fragment("payments_summary")

        redirect_to admin_payments_path, notice: "Paiement annulé avec succès"
      else
        redirect_to admin_payments_path, alert: "Échec de l'annulation du paiement"
      end
    end

    private

    def payment_params
      params.require(:payment).permit(:payment_id, :payment_date, :payment_amount, :payment_type, :status, :user_id, :order_id, :donation, :total_payment)
    end

    def set_breadcrumbs
      add_breadcrumb "Dashboard", admin_dashboard_index_path
    end
  end
end
