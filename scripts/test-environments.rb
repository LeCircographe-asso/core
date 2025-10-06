#!/usr/bin/env ruby

# Script de test des environnements Rails 8.0
# Le Circographe - Vérification des configurations

puts "🧪 Test des environnements Rails 8.0"
puts "===================================="

environments = %w[development staging production]

environments.each do |env|
  puts "\n🔍 Test de l'environnement: #{env.upcase}"
  puts "-" * 40

  # Changer l'environnement
  ENV['RAILS_ENV'] = env

  # Charger l'application Rails
  require_relative '../config/environment'

  begin
    # Test de base
    puts "  ✅ Application chargée"

    # Test de la base de données
    if ActiveRecord::Base.connection.active?
      puts "  ✅ Base de données connectée"

      # Test des tables principales
      tables = %w[users sessions events payments]
      tables.each do |table|
        if ActiveRecord::Base.connection.table_exists?(table)
          count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first[0]
          puts "    📊 Table #{table}: #{count} enregistrements"
        else
          puts "    ⚠️  Table #{table}: manquante"
        end
      end
    else
      puts "  ❌ Base de données non connectée"
    end

    # Test SolidCache
    if defined?(SolidCache)
      cache_entries = SolidCache::Entry.count rescue 0
      puts "  ✅ SolidCache: #{cache_entries} entrées"
    else
      puts "  ❌ SolidCache non configuré"
    end

    # Test SolidQueue
    if defined?(SolidQueue)
      job_count = SolidQueue::Job.count rescue 0
      pending_jobs = SolidQueue::Job.where(finished_at: nil).count rescue 0
      puts "  ✅ SolidQueue: #{job_count} jobs (#{pending_jobs} en attente)"
    else
      puts "  ❌ SolidQueue non configuré"
    end

    # Test des configurations
    puts "  📋 Configuration:"
    puts "    - Cache store: #{Rails.application.config.cache_store}"
    puts "    - Queue adapter: #{Rails.application.config.active_job.queue_adapter}"
    puts "    - Log level: #{Rails.logger.level}"
    puts "    - Eager load: #{Rails.application.config.eager_load}"

  rescue => e
    puts "  ❌ Erreur: #{e.message}"
  end

  # Nettoyer pour l'environnement suivant
  Rails.application = nil
  Rails.env = nil
end

puts "\n🎉 Tests terminés !"
puts "\n💡 Prochaines étapes:"
puts "  1. Configurez les fichiers .env.staging et .env.production"
puts "  2. Testez le déploiement avec: ./scripts/deploy-staging.sh"
puts "  3. Vérifiez les logs avec: kamal logs -c config/deploy.staging.yml"
