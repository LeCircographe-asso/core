# frozen_string_literal: true

module Admin
  module Members
    class PaymentsController < BaseController
      before_action :set_person

      def index
        redirect_to filtered_payments_path
      end

      def show
        redirect_to filtered_payments_path
      end

      def new
        redirect_to filtered_payments_path
      end

      def create
        normalized_lines = normalize_payment_lines(params[:payment_lines])
        lines = normalized_lines.presence || direct_payment_lines
        total_cents = lines.sum { |line| line[:amount_cents].to_i }

        result = People::PaymentRecorder.new(
          person: @person,
          payment_method: payment_params[:payment_method] || "cash",
          recorded_by: Current.user,
          status: "success",
          notes: payment_params[:notes],
          total_cents: total_cents,
          payment_lines: lines
        ).call

        if result.success?
          redirect_to filtered_payments_path, notice: t(".success")
        else
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
        end
      rescue StandardError => e
        redirect_to filtered_payments_path, alert: t(".failure_alert", message: e.message)
      end

      def update
        @payment = @person.payments.find(params[:id])

        total_cents = payment_params[:total_cents]
        total_cents = (total_cents.to_f * 100).to_i if total_cents.present?

        result = People::PaymentUpdater.new(
          payment_id: @payment.id,
          total_cents: total_cents || @payment.total_cents,
          payment_method: payment_params[:payment_method] || @payment.payment_method,
          status: payment_params[:status] || @payment.status,
          notes: payment_params[:notes] || @payment.notes,
          updated_by_id: Current.user.id
        ).call

        if result.success?
          redirect_to filtered_payments_path, notice: t(".success")
        else
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
        end
      end

      def destroy
        @payment = @person.payments.find(params[:id])

        result = People::PaymentCanceller.new(
          payment_id: @payment.id,
          deleted_by_id: Current.user.id,
          reason: "Suppression via interface admin"
        ).call

        if result.success?
          redirect_to filtered_payments_path, notice: t(".destroyed")
        else
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
        end
      end

      def process_payment
        @payment = @person.payments.find(params[:id])

        if @payment.pending?
          result = People::PaymentUpdater.new(
            payment_id: @payment.id,
            status: "success",
            updated_by_id: Current.user.id
          ).call

          if result.success?
            redirect_to filtered_payments_path, notice: t(".processed")
          else
            redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
          end
        else
          redirect_to filtered_payments_path, notice: t(".already_processed")
        end
      rescue StandardError => e
        redirect_to filtered_payments_path, alert: t(".failure_alert", message: e.message)
      end

      private

      def set_person
        person_id = params[:member_id]
        raise ActiveRecord::RecordNotFound, "member_id missing" if person_id.blank?

        @person = Person.find(person_id)
      end

      def payment_params
        params.expect(
          payment: %i[total_cents payment_method status notes recorded_by_id]
        )
      end

      def normalize_payment_lines(lines_param)
        Array(lines_param).compact_blank.map do |line|
          line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
          line.symbolize_keys
        end
      end

      def direct_payment_lines
        [
          {
            item_type: "Donation",
            amount_cents: payment_params[:total_cents].to_i,
            description: "Paiement direct"
          }
        ]
      end

      def filtered_payments_path
        admin_payments_path(person_id: @person.id)
      end
    end
  end
end
