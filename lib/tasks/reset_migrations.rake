namespace :db do
  desc "Reset complet des migrations - ATTENTION: Supprime toutes les données!"
  task reset_migrations: :environment do
    puts "🚨 ATTENTION: Cette opération va supprimer TOUTES les données!"
    puts "=" * 60
    
    unless ENV['FORCE'] == 'true'
      print "Êtes-vous sûr de vouloir continuer? (y/N) "
      response = STDIN.gets.chomp.downcase
      unless response == 'y'
        puts "❌ Opération annulée."
        exit 0
      end
    end

    puts "\n🔄 Début du reset des migrations..."
    
    # 1. Supprimer toutes les migrations existantes
    puts "📁 Suppression des migrations existantes..."
    migration_files = Dir.glob(Rails.root.join('db', 'migrate', '*.rb'))
    migration_files.each do |file|
      File.delete(file)
      puts "  ❌ Supprimé: #{File.basename(file)}"
    end
    
    # 2. Supprimer le schema.rb actuel
    puts "\n📄 Suppression du schema.rb actuel..."
    schema_file = Rails.root.join('db', 'schema.rb')
    if File.exist?(schema_file)
      File.delete(schema_file)
      puts "  ❌ Supprimé: schema.rb"
    end
    
    # 3. Copier le schema propre
    puts "\n📄 Copie du schema propre..."
    clean_schema = Rails.root.join('db', 'schema_clean.rb')
    if File.exist?(clean_schema)
      FileUtils.cp(clean_schema, schema_file)
      puts "  ✅ Copié: schema_clean.rb → schema.rb"
    else
      puts "  ❌ Erreur: schema_clean.rb non trouvé!"
      exit 1
    end
    
    # 4. Créer une migration initiale
    puts "\n📝 Création de la migration initiale..."
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    initial_migration = Rails.root.join('db', 'migrate', "#{timestamp}_initial_schema.rb")
    
    File.write(initial_migration, <<~RUBY)
      class InitialSchema < ActiveRecord::Migration[8.0]
        def change
          # Cette migration charge le schema complet
          # Toutes les tables sont créées via db:schema:load
        end
      end
    RUBY
    
    puts "  ✅ Créé: #{File.basename(initial_migration)}"
    
    # 5. Instructions finales
    puts "\n🎉 Reset des migrations terminé!"
    puts "=" * 60
    puts "📋 Prochaines étapes:"
    puts "  1. rails db:drop"
    puts "  2. rails db:create"
    puts "  3. rails db:schema:load"
    puts "  4. rails db:seed"
    puts ""
    puts "💡 Ou en une commande:"
    puts "  rails db:reset"
    puts ""
    puts "⚠️  N'oubliez pas de faire un commit git avant de continuer!"
  end

  desc "Créer les migrations essentielles à partir du schema propre"
  task create_essential_migrations: :environment do
    puts "📝 Création des migrations essentielles..."
    
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    base_time = Time.current
    
    # Migration 1: Core Tables
    migration1 = Rails.root.join('db', 'migrate', "#{timestamp}_01_create_core_tables.rb")
    File.write(migration1, <<~RUBY)
      class CreateCoreTables < ActiveRecord::Migration[8.0]
        def change
          # These are extensions that must be enabled in order to support this database
          enable_extension "plpgsql"

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
            t.index ["email_address"], name: "index_users_on_email_address", unique: true
            t.index ["person_id"], name: "index_users_on_person_id"
            t.index ["system_role"], name: "index_users_on_system_role"
          end

          add_foreign_key "users", "people"
        end
      end
    RUBY
    
    # Migration 2: Membership System
    migration2 = Rails.root.join('db', 'migrate', "#{(base_time + 1.minute).strftime('%Y%m%d%H%M%S')}_02_create_membership_system.rb")
    File.write(migration2, <<~RUBY)
      class CreateMembershipSystem < ActiveRecord::Migration[8.0]
        def change
          create_table "membership_types", force: :cascade do |t|
            t.string "name", null: false
            t.integer "category", null: false
            t.integer "price_cents", null: false
            t.text "description"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["name"], name: "index_membership_types_on_name", unique: true
          end

          create_table "memberships", force: :cascade do |t|
            t.bigint "person_id", null: false
            t.bigint "membership_type_id", null: false
            t.date "started_at", null: false
            t.date "ended_at", null: false
            t.integer "status", default: 0, null: false
            t.date "first_joined_at"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["person_id"], name: "index_memberships_on_person_id"
            t.index ["membership_type_id"], name: "index_memberships_on_membership_type_id"
            t.index ["status"], name: "index_memberships_on_status"
          end

          add_foreign_key "memberships", "people"
          add_foreign_key "memberships", "membership_types"
        end
      end
    RUBY
    
    # Migration 3: Payment System
    migration3 = Rails.root.join('db', 'migrate', "#{(base_time + 2.minutes).strftime('%Y%m%d%H%M%S')}_03_create_payment_system.rb")
    File.write(migration3, <<~RUBY)
      class CreatePaymentSystem < ActiveRecord::Migration[8.0]
        def change
          create_table "payments", force: :cascade do |t|
            t.bigint "person_id", null: false
            t.bigint "recorded_by_id", null: false
            t.integer "total_cents", null: false
            t.integer "payment_method", default: 0, null: false
            t.integer "status", default: 0, null: false
            t.text "notes"
            t.string "uuid"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["person_id"], name: "index_payments_on_person_id"
            t.index ["recorded_by_id"], name: "index_payments_on_recorded_by_id"
            t.index ["status"], name: "index_payments_on_status"
            t.index ["uuid"], name: "index_payments_on_uuid", unique: true
          end

          create_table "payment_lines", force: :cascade do |t|
            t.bigint "payment_id", null: false
            t.string "item_type", null: false
            t.bigint "item_id", null: false
            t.integer "amount_cents", null: false
            t.string "description"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["payment_id"], name: "index_payment_lines_on_payment_id"
            t.index ["item_type", "item_id"], name: "index_payment_lines_on_item"
          end

          add_foreign_key "payments", "people"
          add_foreign_key "payments", "users", column: "recorded_by_id"
          add_foreign_key "payment_lines", "payments"
        end
      end
    RUBY
    
    puts "✅ Migrations essentielles créées:"
    puts "  📄 #{File.basename(migration1)}"
    puts "  📄 #{File.basename(migration2)}"
    puts "  📄 #{File.basename(migration3)}"
    puts ""
    puts "💡 Vous pouvez maintenant:"
    puts "  rails db:migrate"
  end
end
