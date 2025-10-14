class MakeUserIdNullableInAttendances < ActiveRecord::Migration[8.0]
  def change
    # Rendre user_id nullable pour permettre les présences sans utilisateur
    change_column_null :attendances, :user_id, true
  end
end
