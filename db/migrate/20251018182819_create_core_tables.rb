class CreateCoreTables < ActiveRecord::Migration[8.0]
  def up
    # SQLite3 doesn't require any special extensions

    # Core Tables - Person-Based Architecture
    create_table "people", force: :cascade do |t|
      t.string "first_name", null: false
      t.string "last_name", null: false
      t.string "email", null: false
      t.string "phone"
      t.text "address"
      t.string "zip_code"
      t.string "town"
      t.string "country"
      t.date "birth_date"
      t.string "emergency_contact_name"
      t.string "emergency_contact_phone"
      t.text "notes"
      t.string "occupation"
      t.string "specialty"
      t.boolean "image_rights", default: false
      t.boolean "get_involved", default: false
      t.boolean "newsletter_subscribed", default: false
      t.boolean "dyslexic_font", default: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["email"], name: "index_people_on_email", unique: true
      t.index ["first_name", "last_name"], name: "index_people_on_first_name_and_last_name"
      t.index ["phone"], name: "index_people_on_phone"
    end

    create_table "users", force: :cascade do |t|
      t.string "email_address", null: false
      t.string "password_digest", null: false
      t.string "password_salt"
      t.integer "system_role", default: 3, null: false
      t.string "password_reset_token"
      t.datetime "password_reset_sent_at"
      t.string "unsubscribe_token"
      t.boolean "created_by_admin", default: false
      t.boolean "deleted", default: false
      t.datetime "deleted_at"
      t.bigint "person_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["deleted"], name: "index_users_on_deleted"
      t.index ["email_address"], name: "index_users_on_email_address", unique: true
      t.index ["person_id"], name: "index_users_on_person_id"
      t.index ["system_role"], name: "index_users_on_system_role"
    end

    # Session System (Rails)
    create_table "sessions", force: :cascade do |t|
      t.bigint "user_id", null: false
      t.string "ip_address"
      t.string "user_agent"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["user_id"], name: "index_sessions_on_user_id"
    end

    # Nettoyer les données incompatibles avant d'ajouter les contraintes
    cleanup_invalid_foreign_keys

    # Foreign Keys - avec vérification d'existence
    add_foreign_key "users", "people" unless foreign_key_exists?(:users, :people)
    add_foreign_key "sessions", "users" unless foreign_key_exists?(:sessions, :users)
  end

  def down
    # Supprimer les contraintes de clés étrangères
    remove_foreign_key "sessions", "users" if foreign_key_exists?(:sessions, :users)
    remove_foreign_key "users", "people" if foreign_key_exists?(:users, :people)
    
    # Supprimer les tables
    drop_table "sessions" if table_exists?("sessions")
    drop_table "users" if table_exists?("users")
    drop_table "people" if table_exists?("people")
  end

  private

  def cleanup_invalid_foreign_keys
    # Nettoyer les users avec des person_id invalides
    if table_exists?("users") && table_exists?("people")
      invalid_user_ids = connection.execute(
        "SELECT id FROM users WHERE person_id IS NOT NULL AND person_id NOT IN (SELECT id FROM people)"
      ).map { |row| row["id"] }
      
      if invalid_user_ids.any?
        say "Nettoyage de #{invalid_user_ids.count} users avec des person_id invalides"
        connection.execute("UPDATE users SET person_id = NULL WHERE id IN (#{invalid_user_ids.join(',')})")
      end
    end

    # Nettoyer les sessions avec des user_id invalides
    if table_exists?("sessions") && table_exists?("users")
      invalid_session_ids = connection.execute(
        "SELECT id FROM sessions WHERE user_id NOT IN (SELECT id FROM users)"
      ).map { |row| row["id"] }
      
      if invalid_session_ids.any?
        say "Nettoyage de #{invalid_session_ids.count} sessions avec des user_id invalides"
        connection.execute("DELETE FROM sessions WHERE id IN (#{invalid_session_ids.join(',')})")
      end
    end
  end
end
