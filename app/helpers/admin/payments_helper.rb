# frozen_string_literal: true

module Admin
  module PaymentsHelper
    # Must stay aligned with Admin::PaymentsController::FILTER_PARAM_KEYS
    PAYMENTS_INDEX_QUERY_KEYS = %i[person_id status start_date end_date search sort direction items payment_method donations_only].freeze

    def payments_index_query_filters(source)
      source.to_h.symbolize_keys.slice(*PAYMENTS_INDEX_QUERY_KEYS).compact_blank
    end

    # Le formatage d'affichage d'une ligne de paiement (date, statut, montant, ...)
    # vit désormais dans Admin::Payments::PaymentDisplayComponent (voir _payment_row.html.erb),
    # pas ici — ce helper ne garde que les préoccupations de filtrage de la liste.
  end
end
