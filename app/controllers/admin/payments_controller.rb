# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    # Remove the before_action since we don't need the dashboard breadcrumb
    # before_action :set_breadcrumbs

    def index
      # Use service to handle business logic
      payments_service = Admin::PaymentsService.new(params)
      service_result = payments_service.call

      @payments = service_result[:payments]
      @total_amount = service_result[:total_amount]
      @total_donation = service_result[:total_donation]

      # Handle pagination in controller (service returns the query)
      sort_column = params[:sort] || 'payments.created_at'
      sort_direction = params[:direction] || 'desc'

      # Ensure sort_column is properly qualified with table name
      @payments = if sort_column.include?('.')
                    @payments.order("#{sort_column} #{sort_direction}")
                  else
                    @payments.order("payments.#{sort_column} #{sort_direction}")
                  end

      items_per_page = params[:items]&.to_i || 15
      @pagy, @payments = pagy(@payments, items: items_per_page)

      # Set breadcrumbs
      set_payments_breadcrumbs
    end

    def show
      # Rediriger vers la liste des paiements avec un message
      redirect_to admin_payments_path, notice: "Utilisez l'édition inline pour modifier les paiements"
    end

    def new
      # Payment creation is currently disabled, redirect to index
      redirect_to admin_payments_path, notice: 'Création de paiement temporairement désactivée'
    end

    def edit
      @payment = Payment.find(params[:id])

      respond_to do |format|
        format.html { render partial: 'edit_form', locals: { payment: @payment } }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("payment_#{@payment.id}_actions", partial: 'edit_form', locals: { payment: @payment })
        end
      end
    end

    def create
      # Convertir le montant en centimes si fourni en euros
      total_cents = payment_params[:total_cents]
      total_cents = (total_cents.to_f * 100).to_i if total_cents.present?

      person = Person.find(payment_params[:person_id])

      result = People::PaymentCreator.new(
        person: person,
        amount_cents: total_cents,
        payment_method: payment_params[:payment_method] || 'cash',
        recorded_by_id: Current.user&.id,
        item_type: 'Donation',
        item_id: person.id,
        description: 'Paiement direct',
        notes: payment_params[:notes]
      ).call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_payments_path, notice: 'Paiement créé avec succès' }
          format.turbo_stream do
            payments_service = Admin::PaymentsService.new({})
            payments_service.call

            render turbo_stream: [
              turbo_stream.append('payments', partial: 'payment_row', locals: { payment: result.payment }),
              turbo_stream.replace('payment-summary', partial: 'payment_summary', locals: {
                                     payments: Payment.includes(:person, :recorded_by, :payment_lines).order(created_at: :desc),
                                     total_amount: Payment.total_successful_amount,
                                     total_donation: Payment.total_donations
                                   }),
              turbo_stream.replace('flash', partial: 'shared/flash', locals: { notice: 'Paiement créé avec succès' })
            ]
          end
        else
          format.html { redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement: #{result.message}" }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { alert: "Erreur: #{result.message}" })
          end
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      respond_to do |format|
        format.html { redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement: #{e.message}" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { alert: "Erreur: #{e.message}" })
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Admin::PaymentsController#create] #{e.class}: #{e.message}")
      respond_to do |format|
        format.html { redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement: #{e.message}" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { alert: "Erreur: #{e.message}" })
        end
      end
    end

    # OLD: logique directe (commentée pour rollback)
    # begin
    #   person = Person.find(payment_params[:person_id])
    #   payment = person.payments.create!(
    #     total_cents: payment_params[:total_cents],
    #     payment_method: payment_params[:payment_method] || "cash",
    #     status: :success,
    #     recorded_by: Current.user,
    #     notes: payment_params[:notes]
    #   )
    #   redirect_to admin_payment_path(payment), notice: "Paiement créé avec succès"
    # rescue => e
    #   redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement: #{e.message}"
    # end

    def update
      # Convertir le montant en centimes si fourni en euros
      total_cents = payment_params[:total_cents]
      total_cents = (total_cents.to_f * 100).to_i if total_cents.present?

      result = People::PaymentUpdater.new(
        payment_id: params[:id],
        total_cents: total_cents,
        payment_method: payment_params[:payment_method],
        status: payment_params[:status],
        notes: payment_params[:notes],
        updated_by_id: Current.user.id
      ).call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_payments_path, notice: 'Mise à jour réussie' }
          format.turbo_stream do
            # Recalculer les totaux
            payments_service = Admin::PaymentsService.new({})
            payments_service.call

            render turbo_stream: [
              turbo_stream.replace("payment_#{result.payment.id}_actions", partial: 'payment_actions', locals: { payment: result.payment }),
              turbo_stream.replace("payment_row_#{result.payment.id}", partial: 'payment_row', locals: { payment: result.payment }),
              turbo_stream.replace('payment-summary', partial: 'payment_summary', locals: {
                                     payments: Payment.includes(:person, :recorded_by, :payment_lines).order(created_at: :desc),
                                     total_amount: Payment.total_successful_amount,
                                     total_donation: Payment.total_donations
                                   }),
              turbo_stream.replace('flash', partial: 'shared/flash', locals: { notice: 'Mise à jour réussie' })
            ]
          end
        else
          format.html { redirect_to admin_payment_path(params[:id]), alert: "Échec de la mise à jour: #{result.message}" }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { alert: "Erreur: #{result.message}" })
          end
        end
      end

      # OLD: logique directe (commentée pour rollback)
      # @payment = Payment.find(params[:id])
      # if @payment.update(payment_params)
      #   redirect_to admin_payment_path(@payment), notice: "Mise à jour réussie"
      # else
      #   redirect_to admin_payment_path(@payment), alert: "Échec de la mise à jour"
      # end
    end

    # Add destroy method with soft deletion support
    def destroy
      result = People::PaymentCanceller.new(
        payment_id: params[:id],
        deleted_by_id: Current.user.id,
        reason: 'Suppression via interface admin'
      ).call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_payments_path, notice: 'Paiement annulé avec succès' }
          format.turbo_stream do
            # Recalculer les totaux
            payments_service = Admin::PaymentsService.new({})
            payments_service.call

            render turbo_stream: [
              turbo_stream.remove("payment_row_#{result.payment.id}"),
              turbo_stream.replace('payment-summary', partial: 'payment_summary', locals: {
                                     payments: Payment.includes(:person, :recorded_by, :payment_lines).order(created_at: :desc),
                                     total_amount: Payment.total_successful_amount,
                                     total_donation: Payment.total_donations
                                   }),
              turbo_stream.replace('flash', partial: 'shared/flash', locals: { notice: 'Paiement annulé avec succès' })
            ]
          end
        else
          format.html { redirect_to admin_payments_path, alert: "Échec de l'annulation du paiement: #{result.message}" }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { alert: "Erreur: #{result.message}" })
          end
        end
      end

      # OLD: logique directe (commentée pour rollback)
      # @payment = Payment.find(params[:id])
      # if @payment.update(status: :cancel)
      #   Rails.cache.delete("total_successful_payments")
      #   Rails.cache.delete("total_donations")
      #   expire_fragment(/payments_summary/)
      #   expire_fragment(/payments_total_amount/)
      #   redirect_to admin_payments_path, notice: "Paiement annulé avec succès"
      # else
      #   redirect_to admin_payments_path, alert: "Échec de l'annulation du paiement"
      # end
    end

    # POST /admin/payments/:id/restore
    def restore
      result = People::PaymentRestorer.new(
        payment_id: params[:id],
        restored_by_id: Current.user.id,
        reason: 'Restauration via interface admin'
      ).call

      if result.success?
        redirect_to admin_payment_path(result.payment), notice: 'Paiement restauré avec succès'
      else
        redirect_to admin_payments_path, alert: "Échec de la restauration du paiement: #{result.message}"
      end
    end

    private

    def payment_params
      params.expect(
        payment: [:person_id, :recorded_by_id, :total_cents, :payment_method, :status, :notes,
                  # Compatibilité avec l'ancien modèle
                  :payment_id, :payment_date, :payment_amount, :payment_type, :order_id, :donation, :total_payment]
      )
    end

    def set_payments_breadcrumbs
      if params[:person_id].present?
        person = Person.find_by(id: params[:person_id])
        if person
          add_breadcrumb "Liste d'adhérents", admin_users_path
          add_breadcrumb person.full_name, admin_user_path("person_#{person.id}")
          add_breadcrumb 'Historique des paiements', nil
          return
        end
      end

      if params[:user_id].present?
        user = User.find_by(id: params[:user_id])
        if user
          add_breadcrumb "Liste d'adhérents", admin_users_path
          label = user.full_name.presence || "Utilisateur ##{user.id}"
          add_breadcrumb label, admin_user_path(user)
          add_breadcrumb 'Historique des paiements', nil
          return
        end
      end

      add_breadcrumb 'Historique des paiements', nil
    end
  end
end
