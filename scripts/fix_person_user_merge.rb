#!/usr/bin/env ruby
# Script de réparation pour fusionner Person et User correctement
# Usage: ruby scripts/fix_person_user_merge.rb

require_relative '../config/environment'

puts "🔧 RÉPARATION PERSON-USER MERGE"
puts "=" * 50

# Trouver les Person avec des données mais sans User
people_with_data = Person.joins(:memberships).distinct
puts "Person avec adhésions: #{people_with_data.count}"

# Trouver les User sans Person ou avec Person vide
users_without_data = User.joins(:person).where(people: { id: Person.left_joins(:memberships).where(memberships: { id: nil }) })
puts "User avec Person vide: #{users_without_data.count}"

# Cas spécifique : Person 10 (avec données) et User lié à Person 11 (vide)
person_with_data = Person.find(10)
person_with_user = Person.find(11)
user = person_with_user.user

puts "\n📊 SITUATION ACTUELLE:"
puts "Person 10: #{person_with_data.memberships.count} adhésions, #{person_with_data.payments.count} paiements"
puts "Person 11: #{person_with_user.memberships.count} adhésions, #{person_with_user.payments.count} paiements"
puts "User ID #{user.id} lié à Person: #{user.person_id}"

puts "\n🔧 RÉPARATION EN COURS..."

begin
  ActiveRecord::Base.transaction do
    # Étape 1: Désactiver les validations temporairement
    person_with_user.skip_membership_validation = true
    
    # Étape 2: Supprimer l'email de Person 11 pour éviter le conflit
    person_with_user.update!(email: nil)
    puts "✅ Email de Person 11 supprimé"
    
    # Étape 3: Déplacer le User vers Person 10
    user.update!(person_id: 10)
    puts "✅ User déplacé vers Person 10"
    
    # Étape 4: Supprimer la Person vide
    person_with_user.destroy
    puts "✅ Person 11 supprimée"
    
    puts "\n🎉 RÉPARATION TERMINÉE!"
    puts "Person 10: #{person_with_data.reload.memberships.count} adhésions, #{person_with_data.payments.count} paiements"
    puts "User ID #{user.id} lié à Person: #{user.reload.person_id}"
    
  end
rescue => e
  puts "❌ ERREUR: #{e.message}"
  puts "Rollback effectué"
end

