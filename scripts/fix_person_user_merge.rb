#!/usr/bin/env ruby
# Script legacy de réparation Person/User
# ⚠️ Préférez People::AccountLinker ; ce script démontre son utilisation.
# Usage: ruby scripts/fix_person_user_merge.rb

require_relative '../config/environment'

puts '🔧 RÉPARATION PERSON-USER MERGE'
puts '=' * 50

# Trouver les Person avec des données mais sans User
people_with_data = Person.joins(:memberships).distinct
puts "Person avec adhésions: #{people_with_data.count}"

# Trouver les User sans Person ou avec Person vide
users_without_data = User.joins(:person).where(people: { id: Person.where.missing(:memberships) })
puts "User avec Person vide: #{users_without_data.count}"

# Exemple : Person 10 (données CRM) et User lié à Person 11 (fiche vide)
person_with_data = Person.find(10)
person_with_user = Person.find(11)
user = person_with_user.user

puts "\n📊 SITUATION ACTUELLE:"
puts "Person 10: #{person_with_data.memberships.count} adhésions, #{person_with_data.payments.count} paiements"
puts "Person 11: #{person_with_user.memberships.count} adhésions, #{person_with_user.payments.count} paiements"
puts "User ID #{user.id} lié à Person: #{user.person_id}"

puts "\n🔧 UTILISATION DE People::AccountLinker..."

link_result = People::AccountLinker.new(
  user: user,
  target_person: person_with_data,
  destroy_source_person: true,
  anonymize_source_person: true,
  audit_reason: 'fix_person_user_merge_script'
).call

if link_result.success?
  puts "✅ User ##{link_result.user.id} relié à Person ##{link_result.target_person.id}"
  puts "   Ancienne Person supprimée: #{link_result.source_person&.id}"
  puts "\n🎉 RÉPARATION TERMINÉE!"
else
  puts "❌ ERREUR: #{link_result.message}"
  puts "   Détails: #{link_result.errors.join(', ')}"
end
