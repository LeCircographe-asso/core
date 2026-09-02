# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    rescue_from ActiveRecord::RecordNotFound, with: :redirect_payment_not_found

    def index
      @filter_params = payments_index_filter_params
      service_result = Admin::PaymentsService.new(@filter_params.to_unsafe_h).call

      @total_amount = service_result[:total_amount]
      @total_donation = service_result[:total_donation]

      sorted_payments = apply_payments_sort(service_result[:payments], @filter_params)
      @payments_for_summary = sorted_payments.includes(:person, :recorded_by, :payment_lines)

      items_per_page = @filter_params[:items]&.to_i || 15
      @pagy, @payments = pagy(sorted_payments, items: items_per_page)

      set_payments_breadcrumbs
    end

    def show
      payment = Payment.find(params.expect(:id))
      redirect_to admin_payments_path(person_id: payment.person_id, anchor: "payment_row_#{payment.id}"),
                  notice: t(".use_inline_notice")
    end


    def edit
      @payment = Payment.find(params.expect(:id))
      @list_filter_params = payments_index_filter_params.to_unsafe_h

      respond_to do |format|
        format.html do
          render partial: "edit_form", locals: { payment: @payment, list_filter_params: @list_filter_params }
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "payment_#{@payment.id}_actions",
            partial: "edit_form",
            locals: { payment: @payment, list_filter_params: @list_filter_params }
          )
        end
      end
    end

    def create
      result = build_payment_create_result
      result.success? ? respond_to_created_payment(result) : respond_to_failed_payment_create(result.message)
    rescue ActiveRecord::RecordNotFound => e
      respond_to_failed_payment_create(e.message)
    rescue StandardError => e
      Rails.logger.error("[Admin::PaymentsController#create] #{e.class}: #{e.message}")
      respond_to_failed_payment_create(e.message)
    end

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
        offer_reason: payment_params[:offer_reason],
        updated_by_id: Current.user.id
      ).call

      respond_to do |format|
        if result.success?
          updated_msg = t(".success_notice")
          format.html { redirect_to admin_payments_path, notice: updated_msg }
          format.turbo_stream do
            filter_locals = payments_index_filter_params.to_unsafe_h
            fresh = payment_for_ui_row(result.payment)
            render turbo_stream: [
              turbo_stream.replace("payment_#{fresh.id}_actions", partial: "payment_actions",
                                                                   locals: { payment: fresh, list_filter_params: filter_locals }),
              turbo_stream.replace("payment_row_#{fresh.id}", partial: "payment_row",
                                                               locals: { payment: fresh, list_filter_params: filter_locals }),
              turbo_stream.replace("payment-summary", partial: "payment_summary",
                                                       locals: payment_summary_locals(payments_index_filter_params)),
              turbo_flash_replace(:notice, updated_msg)
            ]
          end
        else
          fail_msg = t(".failure_alert", message: result.message)
          err_detail = I18n.t("flash.generic.error_detail", message: result.message)
          format.html { redirect_to admin_payment_path(params[:id]), alert: fail_msg }
          format.turbo_stream do
            render turbo_stream: turbo_flash_replace(:alert, err_detail)
          end
        end
      end
    end

    def destroy
      result = People::PaymentCanceller.new(
        payment_id: params[:id],
        deleted_by_id: Current.user.id,
        reason: "Suppression via interface admin"
      ).call

      respond_to do |format|
        if result.success?
          cancelled_msg = t(".cancelled_notice")
          format.html { redirect_to admin_payments_path, notice: cancelled_msg }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("payment_row_#{result.payment.id}"),
              turbo_stream.replace("payment-summary", partial: "payment_summary",
                                                     locals: payment_summary_locals(payments_index_filter_params)),
              turbo_flash_replace(:notice, cancelled_msg)
            ]
          end
        else
          fail_msg = t(".cancel_failed_alert", message: result.message)
          err_detail = I18n.t("flash.generic.error_detail", message: result.message)
          format.html { redirect_to admin_payments_path, alert: fail_msg }
          format.turbo_stream do
            render turbo_stream: turbo_flash_replace(:alert, err_detail)
          end
        end
      end
    end

    def restore
      result = People::PaymentRestorer.new(
        payment_id: params[:id],
        restored_by_id: Current.user.id,
        reason: "Restauration via interface admin"
      ).call

      if result.success?
        redirect_to admin_payment_path(result.payment), notice: t(".restored_notice")
      else
        redirect_to admin_payments_path, alert: t(".restore_failed_alert", message: result.message)
      end
    end

    private

    FILTER_PARAM_KEYS = Admin::PaymentsHelper::PAYMENTS_INDEX_QUERY_KEYS

    def redirect_payment_not_found
      redirect_to admin_payments_path, alert: t("admin.payments.not_found_alert")
    end

    def build_payment_create_result
      person = Person.find(payment_create_params[:person_id])
      total_cents = normalized_total_cents(payment_create_params[:total_cents])

      People::PaymentRecorder.new(
        person: person,
        payment_method: payment_create_params[:payment_method] || "cash",
        recorded_by: Current.user,
        status: "success",
        notes: payment_create_params[:notes],
        offer_reason: payment_create_params[:offer_reason],
        total_cents: total_cents,
        payment_lines: direct_payment_lines(total_cents)
      ).call
    end

    def direct_payment_lines(total_cents)
      [
        {
          item_type: "Donation",
          amount_cents: total_cents,
          description: "Paiement direct"
        }
      ]
    end

    def respond_to_created_payment(result)
      created_msg = t(".created_notice")

      respond_to do |format|
        format.html { redirect_to admin_payments_path, notice: created_msg }
        format.turbo_stream do
          filter_locals = payments_index_filter_params.to_unsafe_h
          fresh = payment_for_ui_row(result.payment)
          render turbo_stream: [
            turbo_stream.append("payments", partial: "payment_row",
                                           locals: { payment: fresh, list_filter_params: filter_locals }),
            turbo_stream.replace("payment-summary", partial: "payment_summary",
                                                   locals: payment_summary_locals(payments_index_filter_params)),
            turbo_flash_replace(:notice, created_msg)
          ]
        end
      end
    end

    def respond_to_failed_payment_create(message)
      fail_msg = t("admin.payments.create.failure_alert", message: message)
      err_detail = I18n.t("flash.generic.error_detail", message: message)

      respond_to do |format|
        format.html { redirect_to admin_payments_path, alert: fail_msg }
        format.turbo_stream { render turbo_stream: turbo_flash_replace(:alert, err_detail) }
      end
    end

    def payment_create_params
      @payment_create_params ||= payment_params.to_h.symbolize_keys
    end

    def normalized_total_cents(total_cents)
      return total_cents unless total_cents.present?

      (total_cents.to_f * 100).to_i
    end

    # Filtres liste : uniquement la query string (pas le corps form PATCH), pour éviter les logs
    # Strong Parameters « Unpermitted » sur :payment, :authenticity_token, :controller, etc.
    # Ordre : query courante → GET index → Referer vers la liste.
    def payments_index_filter_params
      direct = permit_payment_index_filters(request.query_parameters)
      return direct if payments_filter_values_present?(direct)

      raw =
        if request.get? && request.path == admin_payments_path
          ActionController::Parameters.new(request.query_parameters)
        elsif request.referer.present?
          uri = URI.parse(request.referer)
          if uri.path == admin_payments_path
            ActionController::Parameters.new(Rack::Utils.parse_nested_query(uri.query.to_s))
          else
            ActionController::Parameters.new({})
          end
        else
          ActionController::Parameters.new({})
        end

      raw.permit(*FILTER_PARAM_KEYS)
    rescue URI::InvalidURIError
      ActionController::Parameters.new({}).permit(*FILTER_PARAM_KEYS)
    end

    def permit_payment_index_filters(query_hash)
      ActionController::Parameters.new(query_hash.to_h).permit(*FILTER_PARAM_KEYS)
    end

    def payments_filter_values_present?(permitted)
      permitted.to_unsafe_h.values.any?(&:present?)
    end

    def payment_for_ui_row(payment_or_id)
      id = payment_or_id.is_a?(Payment) ? payment_or_id.id : payment_or_id
      Payment.includes(:person, :recorded_by, payment_lines: :person).find(id)
    end

    def apply_payments_sort(relation, filter_params)
      sort_column = filter_params[:sort].presence || "payments.created_at"
      sort_direction = filter_params[:direction].presence || "desc"

      if sort_column.to_s.include?(".")
        relation.order("#{sort_column} #{sort_direction}")
      else
        relation.order("payments.#{sort_column} #{sort_direction}")
      end
    end

    def payment_summary_locals(filter_params)
      service_result = Admin::PaymentsService.new(filter_params.to_unsafe_h).call
      sorted = apply_payments_sort(service_result[:payments], filter_params)

      {
        payments: sorted.includes(:person, :recorded_by, :payment_lines),
        total_amount: service_result[:total_amount],
        total_donation: service_result[:total_donation]
      }
    end

    def payment_params
      params.expect(
        payment: [ :person_id, :recorded_by_id, :total_cents, :payment_method, :status, :notes, :offer_reason,
                  # Compatibilité avec l'ancien modèle
                  :payment_id, :payment_date, :payment_amount, :payment_type, :order_id, :donation, :total_payment ]
      )
    end

    def set_payments_breadcrumbs
      if params[:person_id].present?
        person = Person.find_by(id: params[:person_id])
        if person
          add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), admin_members_path
          add_breadcrumb person.full_name, admin_member_path(person)
          add_breadcrumb I18n.t("breadcrumbs.admin.payments.history"), nil
          return
        end
      end

      add_breadcrumb I18n.t("breadcrumbs.admin.payments.history"), nil
    end

    def turbo_flash_replace(type, message)
      turbo_stream.replace("flash", partial: "shared/flash", locals: { type => message })
    end
  end
end
