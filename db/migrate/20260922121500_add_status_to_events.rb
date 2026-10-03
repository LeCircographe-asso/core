# frozen_string_literal: true

class AddStatusToEvents < ActiveRecord::Migration[8.1]
  def change
    # Défaut à "draft" : un événement créé par un admin doit être publié
    # explicitement avant d'apparaître sur les pages publiques (home,
    # /actualites, /events/:id).
    add_column :events, :status, :integer, default: 0, null: false
    add_index :events, :status
  end
end
