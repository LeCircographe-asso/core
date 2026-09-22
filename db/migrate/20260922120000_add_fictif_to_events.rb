# frozen_string_literal: true

class AddFictifToEvents < ActiveRecord::Migration[8.1]
  def change
    # Défaut à true : tant que le site n'est pas ouvert au public, aucun
    # événement créé n'est réel. Un admin décochera la case au cas par cas
    # une fois en prod, pour les vrais événements — les événements de test
    # resteront marqués "fictif" et garderont le badge public.
    add_column :events, :fictif, :boolean, default: true, null: false
  end
end
