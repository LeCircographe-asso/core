namespace :db do
  desc "Remove all imported members (cleanup for re-import testing)"
  task cleanup_imports: :environment do
    puts "🗑️  Suppression des adhérents créés aujourd'hui..."

    people = Person.where("DATE(created_at) = ?", Date.current)
    count = people.count
    person_ids = people.pluck(:id)

    if person_ids.any?
      payment_ids = Payment.where(person_id: person_ids).pluck(:id)

      # Ordre imposé par les FK : audit logs et lignes avant les paiements,
      # paiements/adhésions/cotisations/présences avant la personne.
      ActiveRecord::Base.connection.execute("DELETE FROM payment_audit_logs WHERE payment_id IN (#{payment_ids.join(',')})") if payment_ids.any?
      ActiveRecord::Base.connection.execute("DELETE FROM payment_lines WHERE payment_id IN (#{payment_ids.join(',')})") if payment_ids.any?
      Payment.where(id: payment_ids).delete_all
      Membership.where(person_id: person_ids).delete_all
      Contribution.where(person_id: person_ids).delete_all
      Attendance.where(person_id: person_ids).delete_all
      NewsletterSubscriber.where(email: people.pluck(:email).compact).delete_all
      Person.where(id: person_ids).delete_all
    end

    puts "✓ #{count} adhérents supprimés"
    puts "✓ Base de données nettoyée - prêt pour réimport"
  end
end
