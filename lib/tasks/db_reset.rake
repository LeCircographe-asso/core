namespace :db do
  desc "Reset complet de la base de données (drop, create, migrate, seed)"
  task :full_reset => :environment do
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
    
    unless ['oui', 'o', 'yes', 'y'].include?(confirmation)
      puts "❌ Opération annulée"
      exit 0
    end
    
    puts "\n🚀 Début du reset..."
    
    begin
      # 1. Drop database
      puts "1️⃣  Suppression de la base de données..."
      Rake::Task['db:drop'].invoke
      
      # 2. Create database
      puts "2️⃣  Création de la base de données..."
      Rake::Task['db:create'].invoke
      
      # 3. Run migrations
      puts "3️⃣  Exécution des migrations..."
      Rake::Task['db:migrate'].invoke
      
      # 4. Seed database
      puts "4️⃣  Peuplement de la base de données..."
      Rake::Task['db:seed'].invoke
      
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
  task :force_reset => :environment do
    puts "🔄 Reset forcé de la base de données..."
    puts "📊 Environnement: #{Rails.env}"
    
    begin
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:seed'].invoke
      
      puts "✅ Reset forcé terminé avec succès !"
      
    rescue => e
      puts "❌ Erreur lors du reset forcé: #{e.message}"
      exit 1
    end
  end

  desc "Afficher les informations de la base de données"
  task :info => :environment do
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
      migrations = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM schema_migrations").first['count']
      puts "   Migrations appliquées: #{migrations}"
    else
      puts "   Status: ❌ Non connectée"
    end
  end
end
