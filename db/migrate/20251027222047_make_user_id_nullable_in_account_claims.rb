class MakeUserIdNullableInAccountClaims < ActiveRecord::Migration[8.1]
  def change
    change_column_null :account_claims, :user_id, true
  end
end
