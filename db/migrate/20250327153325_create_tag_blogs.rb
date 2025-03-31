class CreateTagBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_blogs do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true

      t.timestamps
    end
  end
end
