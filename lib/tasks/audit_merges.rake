# frozen_string_literal: true

namespace :security do
  desc "Audit des fusions de comptes"
  task audit_merges: :environment do
    puts "=== AUDIT DES FUSIONS DE COMPTES ==="
    puts "Date: #{Time.current}"
    puts ""

    # Person archivées récemment
    archived = Person.archived.where("deleted_at > ?", 30.days.ago)
    puts "Person archivées (30 derniers jours): #{archived.count}"

    archived.each do |person|
      puts "\n---"
      puts "Person ID: #{person.id}"
      puts "Nom: #{person.full_name}"
      puts "Email: #{person.email}"
      puts "Archivé le: #{person.deleted_at}"
      puts "Paiements: #{person.payments.count}"
      puts "Adhésions: #{person.memberships.count}"

      puts "⚠️  ATTENTION: Person avec données financières archivée" if person.payments.any? || person.memberships.any?
    end

    puts "\n=== FIN DE L'AUDIT ==="
  end

  desc "Vérifier les doublons potentiels"
  task check_duplicates: :environment do
    puts "=== VÉRIFICATION DES DOUBLONS ==="

    # Doublons par email
    email_duplicates = Person.active
                             .where.not(email: [ nil, "" ])
                             .group(:email)
                             .having("COUNT(*) > 1")
                             .count

    puts "Emails en doublon: #{email_duplicates.count}"

    email_duplicates.each do |email, count|
      puts "\n#{email}: #{count} Person"
      Person.active.where(email: email).find_each do |p|
        puts "  - Person #{p.id}: #{p.full_name} (User: #{p.user_id || 'aucun'})"
      end
    end

    puts "\n=== FIN DE LA VÉRIFICATION ==="
  end
end
