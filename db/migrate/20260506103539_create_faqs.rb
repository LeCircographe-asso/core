class CreateFaqs < ActiveRecord::Migration[8.1]
  def change
    create_table :faqs do |t|
      t.string  :question, null: false
      t.text    :answer,   null: false
      t.string  :label,    null: false, default: "general"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :faqs, :label
    add_index :faqs, [ :label, :position ]
  end
end
