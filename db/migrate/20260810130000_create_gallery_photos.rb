class CreateGalleryPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :gallery_photos do |t|
      t.bigint :created_by_user_id

      t.timestamps
    end

    add_index :gallery_photos, :created_by_user_id
  end
end
