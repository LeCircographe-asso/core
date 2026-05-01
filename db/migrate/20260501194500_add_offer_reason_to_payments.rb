class AddOfferReasonToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :offer_reason, :text
  end
end
