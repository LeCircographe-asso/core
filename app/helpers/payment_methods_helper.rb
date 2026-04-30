# frozen_string_literal: true

module PaymentMethodsHelper
  def payment_method_options(include_pending: false)
    options = [
      [ "Espèces", "cash" ],
      [ "Carte bancaire", "card" ],
      [ "Chèque", "cheque" ],
      [ "Virement", "transfer" ],
      [ "Offert", "offered" ]
    ]
    options << [ "À payer plus tard", "pending" ] if include_pending
    options
  end
end
