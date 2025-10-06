#!/usr/bin/env ruby

# Script simple pour tester l'authentification
puts "🔐 Test de l'authentification..."

require_relative '../config/environment'

# Nettoyer toutes les sessions
puts "🧹 Nettoyage des sessions..."
Session.delete_all
puts "✅ Sessions nettoyées"

# Vérifier l'état
puts "📊 État actuel:"
puts "  - Sessions: #{Session.count}"
puts "  - Utilisateurs: #{User.count}"

# Tester la connexion avec un utilisateur
user = User.first
if user
  puts "👤 Test avec utilisateur: #{user.email_address}"
  
  # Créer une session de test
  session = user.sessions.create!(
    user_agent: "Test Script",
    ip_address: "127.0.0.1"
  )
  puts "✅ Session de test créée: #{session.id}"
else
  puts "❌ Aucun utilisateur trouvé"
end

puts "🎉 Test terminé !"
