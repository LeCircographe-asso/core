class MakeUserIdNullableInPayments < ActiveRecord::Migration[8.0]
  def change
    # Rendre user_id nullable pour permettre les paiements sans utilisateur
    change_column_null :payments, :user_id, true
  end
end
