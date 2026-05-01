class AddEmailChangeVerificationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :pending_email_address, :string
    add_column :users, :email_change_code_digest, :string
    add_column :users, :email_change_code_sent_at, :datetime
  end
end
