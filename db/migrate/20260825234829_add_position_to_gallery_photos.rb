# frozen_string_literal: true

class AddPositionToGalleryPhotos < ActiveRecord::Migration[8.1]
  def up
    add_column :gallery_photos, :position, :integer

    say_with_time "Backfilling gallery_photos.position from created_at order" do
      execute <<~SQL
        UPDATE gallery_photos
        SET position = sub.rank
        FROM (
          SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) AS rank
          FROM gallery_photos
        ) AS sub
        WHERE gallery_photos.id = sub.id
      SQL
    end

    change_column_null :gallery_photos, :position, false
    add_index :gallery_photos, :position
  end

  def down
    remove_column :gallery_photos, :position
  end
end
