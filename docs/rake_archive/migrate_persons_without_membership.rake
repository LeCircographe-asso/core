# =====================================================================
# LEGACY ARCHIVE — NE PAS RECHARGER
# ---------------------------------------------------------------------
# Tâche Rake one-shot conservée pour mémoire historique. Elle a comblé
# un gap de données lors d'une migration passée. Ne pas la déplacer
# dans lib/tasks/ ni l'exécuter en runtime.
# =====================================================================

namespace :migrate do
  desc "Migrate existing persons without active membership to have basic membership"
  task persons_without_membership: :environment do
    puts "🔄 Migration des Person sans adhésion active..."
    puts "=" * 60

    # Trouver l'adhésion Basic par défaut
    basic_membership_type = MembershipType.find_by(category: :basic)

    if basic_membership_type.nil?
      puts "❌ Erreur: Aucune adhésion Basic trouvée!"
      puts "   Créez d'abord les MembershipType avec: rails db:seed"
      exit 1
    end

    # Trouver un admin pour recorded_by
    admin_user = User.find_by(system_role: [ :admin, :super_admin ])

    if admin_user.nil?
      puts "❌ Erreur: Aucun admin trouvé pour recorded_by!"
      exit 1
    end

    # Identifier les Person sans adhésion active
    persons_without_membership = Person.where.not(
      id: Person.joins(:memberships).where(memberships: { status: :active }).select(:id)
    )

    puts "📊 Statistiques:"
    puts "   - Total Person: #{Person.count}"
    puts "   - Person sans adhésion active: #{persons_without_membership.count}"
    puts "   - Adhésion Basic: #{basic_membership_type.name} (#{basic_membership_type.price_euros}€)"
    puts "   - Admin: #{admin_user.full_name}"
    puts ""

    if persons_without_membership.empty?
      puts "✅ Toutes les Person ont déjà une adhésion active!"
      exit 0
    end

    # Demander confirmation
    puts "⚠️  Cette opération va créer des adhésions et des paiements pour #{persons_without_membership.count} personnes."
    puts "   Voulez-vous continuer? (y/N)"

    unless ENV["FORCE"] == "true"
      response = STDIN.gets.chomp.downcase
      unless response == "y" || response == "yes"
        puts "❌ Migration annulée."
        exit 0
      end
    end

    puts ""
    puts "🚀 Début de la migration..."

    success_count = 0
    error_count = 0

    persons_without_membership.find_each do |person|
      begin
        ActiveRecord::Base.transaction do
          data = person.create_membership!(
            basic_membership_type,
            payment_method: :cash,
            recorded_by: admin_user
          )

          puts "  ✅ #{person.full_name} - Adhésion créée"
          success_count += 1
        end
      rescue => e
        puts "  ❌ #{person.full_name} - Erreur: #{e.message}"
        error_count += 1
      end
    end

    puts ""
    puts "🎉 Migration terminée!"
    puts "=" * 60
    puts "📊 Résultats:"
    puts "   - Succès: #{success_count}"
    puts "   - Erreurs: #{error_count}"
    puts "   - Total traité: #{success_count + error_count}"

    # Vérification finale
    remaining_without_membership = Person.where.not(
      id: Person.joins(:memberships).where(memberships: { status: :active }).select(:id)
    ).count

    if remaining_without_membership == 0
      puts "✅ Toutes les Person ont maintenant une adhésion active!"
    else
      puts "⚠️  #{remaining_without_membership} Person n'ont toujours pas d'adhésion active."
    end

    puts ""
    puts "💡 Pour forcer la migration sans confirmation, utilisez:"
    puts "   FORCE=true rails migrate:persons_without_membership"
  end
end
