#!/usr/bin/env ruby

# Script simple de nettoyage - Le Circographe
puts "🧹 Nettoyage simple de la base de données..."

# Charger Rails
require_relative '../config/environment'

# 1. Nettoyer SolidCache (si disponible)
if defined?(SolidCache)
  cache_entries = SolidCache::Entry.count
  SolidCache::Entry.where('expires_at < ?', Time.current).delete_all
  puts "✅ SolidCache nettoyé (#{cache_entries} entrées)"
end

# 2. Nettoyer SolidQueue (si disponible)
if defined?(SolidQueue)
  old_jobs = SolidQueue::Job.where.not(finished_at: nil)
                            .where('finished_at < ?', 7.days.ago)
                            .count
  SolidQueue::Job.where.not(finished_at: nil)
                 .where('finished_at < ?', 7.days.ago)
                 .delete_all
  puts "✅ SolidQueue nettoyé (#{old_jobs} jobs anciens supprimés)"
end

# 3. Optimiser la base de données
ActiveRecord::Base.connection.execute("VACUUM")
puts "✅ Base de données optimisée"

puts "🎉 Nettoyage terminé !"
