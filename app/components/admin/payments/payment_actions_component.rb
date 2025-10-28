module Admin
  module Payments
    class PaymentActionsComponent < ViewComponent::Base
      def initialize(payment:)
        @payment = payment
      end

      private

      attr_reader :payment

      def view_action
        link_to admin_payment_path(payment), 
                class: "text-[#1F5C55] hover:text-[#194A45] mr-2", 
                title: "Voir le détail" do
          content_tag :svg, 
                      class: "h-5 w-5", 
                      fill: "none", 
                      viewBox: "0 0 24 24", 
                      stroke: "currentColor" do
            content_tag :path, 
                        nil,
                        "stroke-linecap": "round",
                        "stroke-linejoin": "round", 
                        "stroke-width": "2",
                        d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
          end
        end
      end

      def edit_action
        link_to edit_admin_payment_path(payment), 
                class: "text-blue-600 hover:text-blue-800 mr-2", 
                title: "Modifier" do
          content_tag :svg, 
                      class: "h-5 w-5", 
                      fill: "none", 
                      viewBox: "0 0 24 24", 
                      stroke: "currentColor" do
            content_tag :path, 
                        nil,
                        "stroke-linecap": "round",
                        "stroke-linejoin": "round", 
                        "stroke-width": "2",
                        d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
          end
        end
      end

      def cancel_action
        if payment.status != "cancel"
          button_to admin_payment_path(payment), 
                    method: :delete, 
                    class: "text-red-600 hover:text-red-800", 
                    title: "Annuler le paiement",
                    data: { 
                      confirm: "Êtes-vous sûr de vouloir annuler ce paiement ?",
                      turbo_method: :delete
                    } do
            content_tag :svg, 
                        class: "h-5 w-5", 
                        fill: "none", 
                        viewBox: "0 0 24 24", 
                        stroke: "currentColor" do
              content_tag :path, 
                          nil,
                          "stroke-linecap": "round",
                          "stroke-linejoin": "round", 
                          "stroke-width": "2",
                          d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
            end
          end
        end
      end

      def actions
        [view_action, edit_action, cancel_action].compact
      end
    end
  end
end
