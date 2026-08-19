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

      # Puce cliquable : fond + bordure toujours visibles (pas juste une icône colorée dans le
      # vide) pour lire clairement comme un bouton, cohérent avec le style déjà utilisé pour
      # "Reçu"/"Renvoyer" plus bas.
      ACTION_CHIP_CLASSES = "inline-flex items-center justify-center w-8 h-8 rounded-md border transition-colors mr-1.5"

      def view_action
        # Rediriger vers la personne si elle a un user, sinon vers la liste
        if payment.person&.user
          link_to admin_member_path(payment.person),
                  class: "#{ACTION_CHIP_CLASSES} border-[#1F5C55]/20 bg-[#1F5C55]/5 text-[#1F5C55] hover:bg-[#1F5C55]/10 hover:border-[#1F5C55]/30",
                  title: "Voir la personne" do
            content_tag :svg,
                        class: "h-4 w-4",
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
                      class: "#{ACTION_CHIP_CLASSES} border-gray-200 bg-gray-50 text-gray-300 cursor-not-allowed",
                      title: "Aucun utilisateur associé" do
            content_tag :svg,
                        class: "h-4 w-4",
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
                class: "#{ACTION_CHIP_CLASSES} border-blue-200 bg-blue-50 text-blue-600 hover:bg-blue-100 hover:border-blue-300",
                title: "Modifier",
                data: {
                  turbo_frame: "payment_#{payment.id}_actions"
                } do
          content_tag :svg,
                      class: "h-4 w-4",
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
                  class: "#{ACTION_CHIP_CLASSES} border-red-200 bg-red-50 text-red-600 hover:bg-red-100 hover:border-red-300 !mr-0",
                  title: "Annuler le paiement" do
          content_tag :svg,
                      class: "h-4 w-4",
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

      def donation_line
        return @donation_line if defined?(@donation_line)

        @donation_line = payment.payment_lines.to_a.find { |line| line.item_type == "Donation" }
      end

      def donation_receipt_action
        return unless donation_line
        return unless payment.status == "success"

        if donation_line.donation_receipt.present?
          safe_join([
            link_to(helpers.admin_payment_donation_receipt_path(payment),
                    class: "#{ACTION_CHIP_CLASSES} border-[#1F5C55]/20 bg-[#1F5C55]/5 text-[#1F5C55] hover:bg-[#1F5C55]/10 hover:border-[#1F5C55]/30",
                    title: "Télécharger le reçu",
                    target: "_blank",
                    rel: "noopener") do
              content_tag :svg, class: "h-4 w-4", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
                content_tag :path, nil, 'stroke-linecap': "round", 'stroke-linejoin': "round", 'stroke-width': "2",
                            d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              end
            end,
            button_to(helpers.resend_admin_payment_donation_receipt_path(payment),
                      method: :post,
                      form: { data: { turbo_frame: "_top" } },
                      class: "#{ACTION_CHIP_CLASSES} border-gray-200 bg-gray-50 text-gray-600 hover:bg-gray-100 hover:border-gray-300 !w-auto px-2 text-xs font-medium",
                      title: "Renvoyer le reçu par email") { "Renvoyer" }
          ], "")
        else
          button_to helpers.admin_payment_donation_receipt_path(payment),
                    method: :post,
                    form: { data: { turbo_frame: "_top" } },
                    class: "#{ACTION_CHIP_CLASSES} border-gray-200 bg-gray-50 text-gray-600 hover:bg-gray-100 hover:border-gray-300 !w-auto px-2 text-xs font-medium",
                    title: "Émettre le reçu de don" do
            "Reçu"
          end
        end
      end

      def actions
        [ view_action, edit_action, donation_receipt_action, cancel_action ].compact
      end
    end
  end
end
