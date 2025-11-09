namespace :db do
  desc "Reset complet de la base de données (drop, create, migrate, seed)"
  task full_reset: :environment do
    puts "🔄 Reset complet de la base de données..."
    puts "⚠️  ATTENTION: Cette action va supprimer TOUTES les données !"

    if Rails.env.production?
      puts "❌ ERREUR: Reset interdit en production !"
      puts "   Utilisez: rails db:reset RAILS_ENV=production"
      puts "   Ou connectez-vous manuellement à la BDD pour un reset sécurisé"
      exit 1
    end

    puts "📊 Environnement: #{Rails.env}"
    puts "🗄️  Base de données: #{Rails.configuration.database_configuration[Rails.env]['database']}"

    # Demander confirmation
    print "Êtes-vous sûr de vouloir continuer ? (oui/non): "
    confirmation = STDIN.gets.chomp.downcase

    unless [ "oui", "o", "yes", "y" ].include?(confirmation)
      puts "❌ Opération annulée"
      exit 0
    end

    puts "\n🚀 Début du reset..."

    begin
      # 1. Drop database
      puts "1️⃣  Suppression de la base de données..."
      Rake::Task["db:drop"].invoke

      # 2. Create database
      puts "2️⃣  Création de la base de données..."
      Rake::Task["db:create"].invoke

      # 3. Run migrations
      puts "3️⃣  Exécution des migrations..."
      Rake::Task["db:migrate"].invoke

      # 4. Seed database
      puts "4️⃣  Peuplement de la base de données..."
      Rake::Task["db:seed"].invoke

      puts "\n✅ Reset complet terminé avec succès !"
      puts "🎉 La base de données est prête à l'utilisation"

    rescue => e
      puts "\n❌ Erreur lors du reset:"
      puts "   #{e.message}"
      puts "\n🔧 Vérifiez la configuration de votre base de données"
      exit 1
    end
  end

  desc "Reset de la base de données avec confirmation forcée (pour scripts)"
  task force_reset: :environment do
    puts "🔄 Reset forcé de la base de données..."
    puts "📊 Environnement: #{Rails.env}"

    begin
      # For SQLite, manually delete ALL database files first (main, cache, queue, cable)
      db_config = Rails.configuration.database_configuration
      dbs_to_delete = []
      dbs_to_delete << db_config[Rails.env]["database"] if db_config[Rails.env]["database"]
      dbs_to_delete << db_config[Rails.env + "_cache"]["database"] if db_config[Rails.env + "_cache"]
      dbs_to_delete << db_config[Rails.env + "_queue"]["database"] if db_config[Rails.env + "_queue"]
      dbs_to_delete << db_config[Rails.env + "_cable"]["database"] if db_config[Rails.env + "_cable"]
      dbs_to_delete.compact!

      dbs_to_delete.each do |db_path|
        if db_path && File.exist?(db_path)
          puts "🗑️  Suppression du fichier: #{db_path}"
          File.delete(db_path)
        elsif db_path
          puts "ℹ️  Fichier n'existe pas: #{db_path}"
        end
      end

      # Also delete any journal/WAL files
      dbs_to_delete.each do |db_path|
        next unless db_path
        journal_file = db_path + "-journal"
        wal_file = db_path + "-wal"
        shm_file = db_path + "-shm"
        [ journal_file, wal_file, shm_file ].each do |extra_file|
          if File.exist?(extra_file)
            puts "🗑️  Suppression du fichier temporaire: #{extra_file}"
            File.delete(extra_file)
          end
        end
      end

      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke

      puts "✅ Reset forcé terminé avec succès !"

    rescue => e
      puts "❌ Erreur lors du reset forcé: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      exit 1
    end
  end

  desc "Afficher les informations de la base de données"
  task info: :environment do
    config = Rails.configuration.database_configuration[Rails.env]

    puts "📊 Informations de la base de données:"
    puts "   Environnement: #{Rails.env}"
    puts "   Adapter: #{config['adapter']}"
    puts "   Base de données: #{config['database']}"
    puts "   Host: #{config['host'] || 'localhost'}"
    puts "   Port: #{config['port'] || 'default'}"
    puts "   Username: #{config['username'] || 'default'}"

    if ActiveRecord::Base.connection.active?
      puts "   Status: ✅ Connectée"

      # Compter les tables
      tables = ActiveRecord::Base.connection.tables
      puts "   Tables: #{tables.count}"

      # Compter les migrations
      migrations = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM schema_migrations").first["count"]
      puts "   Migrations appliquées: #{migrations}"
    else
      puts "   Status: ❌ Non connectée"
    end
  end
end
