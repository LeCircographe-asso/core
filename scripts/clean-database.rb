#!/usr/bin/env ruby

# Script de nettoyage de la base de données
# Le Circographe - Suppression des fonctions inutiles et nettoyage

puts "🧹 Script de nettoyage de la base de données Le Circographe"
puts "=========================================================="

# Charger l'environnement Rails
require_relative '../config/environment'

puts "📊 État actuel de la base de données:"
puts "  - Utilisateurs: #{User.count}"
puts "  - Commandes: #{Order.count}"
puts "  - Paiements: #{Payment.count}"
puts "  - Logs d'audit: #{PaymentAuditLog.count}"
puts "  - Événements: #{Event.count}"
puts "  - Présences: #{Attendance.count}"
puts ""

# 1. Nettoyer les logs d'audit anciens (> 1 an)
puts "🗑️  Nettoyage des logs d'audit anciens..."
old_audit_logs = PaymentAuditLog.where('created_at < ?', 1.year.ago)
if old_audit_logs.count > 0
  puts "  - Suppression de #{old_audit_logs.count} logs d'audit anciens"
  old_audit_logs.delete_all
else
  puts "  - Aucun log d'audit ancien trouvé"
end

# 2. Nettoyer les paiements annulés anciens (> 6 mois)
puts "🗑️  Nettoyage des paiements annulés anciens..."
old_cancelled_payments = Payment.where(status: 'cancel')
                                .where('created_at < ?', 6.months.ago)
if old_cancelled_payments.count > 0
  puts "  - Suppression de #{old_cancelled_payments.count} paiements annulés anciens"
  old_cancelled_payments.delete_all
else
  puts "  - Aucun paiement annulé ancien trouvé"
end

# 3. Nettoyer les événements passés avec aucun participant (> 2 ans)
puts "🗑️  Nettoyage des événements passés sans participants..."
old_events = Event.where('date < ?', 2.years.ago)
                  .left_joins(:event_attendees)
                  .where(event_attendees: { id: nil })
if old_events.count > 0
  puts "  - Suppression de #{old_events.count} événements passés sans participants"
  old_events.delete_all
else
  puts "  - Aucun événement passé sans participants trouvé"
end

# 4. Nettoyer les carnets d'entrées expirés (remaining = 0)
puts "🗑️  Nettoyage des carnets d'entrées expirés..."
expired_books = BookOfEntry.where(remaining: 0)
if expired_books.count > 0
  puts "  - Suppression de #{expired_books.count} carnets d'entrées expirés"
  expired_books.delete_all
else
  puts "  - Aucun carnet d'entrées expiré trouvé"
end

# 5. Nettoyer les présences orphelines (utilisateurs supprimés)
puts "🗑️  Nettoyage des présences orphelines..."
orphaned_attendances = Attendance.left_joins(:user)
                                .where(users: { id: nil })
if orphaned_attendances.count > 0
  puts "  - Suppression de #{orphaned_attendances.count} présences orphelines"
  orphaned_attendances.delete_all
else
  puts "  - Aucune présence orpheline trouvée"
end

# 6. Optimiser la base de données SQLite
puts "🔧 Optimisation de la base de données..."
ActiveRecord::Base.connection.execute("VACUUM")
ActiveRecord::Base.connection.execute("ANALYZE")
puts "  - Base de données optimisée ✓"

puts ""
puts "✅ Nettoyage terminé!"
puts ""
puts "📊 État final de la base de données:"
puts "  - Utilisateurs: #{User.count}"
puts "  - Commandes: #{Order.count}"
puts "  - Paiements: #{Payment.count}"
puts "  - Logs d'audit: #{PaymentAuditLog.count}"
puts "  - Événements: #{Event.count}"
puts "  - Présences: #{Attendance.count}"
