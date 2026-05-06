# frozen_string_literal: true

module Admin
  module Payments
    class PaymentActionsComponent < ViewComponent::Base
      def initialize(payment:, list_filter_params: {})
        @payment = payment
        @list_filter_params = list_filter_params
      end

      private

      attr_reader :payment, :list_filter_params

      def path_filters
        helpers.payments_index_query_filters(list_filter_params)
      end

      def view_action
        # Rediriger vers la personne si elle a un user, sinon vers la liste
        if payment.person&.user
          link_to admin_member_path(payment.person),
                  class: "text-[#1F5C55] hover:text-[#194A45] mr-2",
                  title: "Voir la personne" do
            content_tag :svg,
                        class: "h-5 w-5",
                        fill: "none",
                        viewBox: "0 0 24 24",
                        stroke: "currentColor" do
              content_tag :path,
                          nil,
                          'stroke-linecap': "round",
                          'stroke-linejoin': "round",
                          'stroke-width': "2",
                          d: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            end
          end
        else
          content_tag :span,
                      class: "text-gray-400 mr-2",
                      title: "Aucun utilisateur associé" do
            content_tag :svg,
                        class: "h-5 w-5",
                        fill: "none",
                        viewBox: "0 0 24 24",
                        stroke: "currentColor" do
              content_tag :path,
                          nil,
                          'stroke-linecap': "round",
                          'stroke-linejoin': "round",
                          'stroke-width': "2",
                          d: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            end
          end
        end
      end

      def edit_action
        link_to helpers.edit_admin_payment_path(payment, **path_filters),
                class: "text-blue-600 hover:text-blue-800 mr-2",
                title: "Modifier",
                data: {
                  turbo_frame: "payment_#{payment.id}_actions"
                } do
          content_tag :svg,
                      class: "h-5 w-5",
                      fill: "none",
                      viewBox: "0 0 24 24",
                      stroke: "currentColor" do
            content_tag :path,
                        nil,
                        'stroke-linecap': "round",
                        'stroke-linejoin': "round",
                        'stroke-width': "2",
                        d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
          end
        end
      end

      def cancel_action
        return unless payment.status != "cancel"

        button_to helpers.admin_payment_path(payment, **path_filters),
                  method: :delete,
                  form: {
                    data: {
                      turbo_confirm: "Êtes-vous sûr de vouloir annuler ce paiement ?",
                      turbo_frame: "_top"
                    }
                  },
                  class: "text-red-600 hover:text-red-800",
                  title: "Annuler le paiement" do
          content_tag :svg,
                      class: "h-5 w-5",
                      fill: "none",
                      viewBox: "0 0 24 24",
                      stroke: "currentColor" do
            content_tag :path,
                        nil,
                        'stroke-linecap': "round",
                        'stroke-linejoin': "round",
                        'stroke-width': "2",
                        d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
          end
        end
      end

      def actions
        [ view_action, edit_action, cancel_action ].compact
      end
    end
  end
end
