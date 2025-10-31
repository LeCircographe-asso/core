class CreateNewsletterSubscribers < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletter_subscribers do |t|
      t.string :email, null: false
      t.boolean :subscribed, default: true, null: false
      t.string :unsubscribe_token
      t.datetime :subscribed_at
      t.datetime :unsubscribed_at
      t.bigint :person_id # Nullable - link si Person existe
      t.string :source # 'web', 'admin', 'import'
      t.text :notes
      
      t.timestamps
      
      t.index :email, unique: true
      t.index :person_id
      t.index [:subscribed, :email]
      t.index :unsubscribe_token, unique: true
    end
    
    add_foreign_key :newsletter_subscribers, :people, column: :person_id, on_delete: :nullify
  end
end
