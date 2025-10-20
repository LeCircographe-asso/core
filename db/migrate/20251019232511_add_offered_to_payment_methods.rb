class AddOfferedToPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    # Rails utilise des entiers pour les enums, donc pas besoin de migration
    # La valeur 'offered' sera automatiquement ajoutée avec la valeur 4
    # (cash=0, sumup=1, cheque=2, transfer=3, offered=4)
  end
end
