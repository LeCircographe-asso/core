# frozen_string_literal: true

# =====================================================================
# LEGACY ARCHIVE — NE PAS RECHARGER
# ---------------------------------------------------------------------
# Cette tâche Rake est conservée pour mémoire historique uniquement.
# Elle a été exécutée lors de la migration vers l'architecture Person-Based
# (cf. docs/migrations/vocabulary_migration.md). Le code peut référencer
# des modèles ou colonnes qui n'existent plus.
#
# Ne pas l'inclure dans lib/tasks/ ni dans aucun runner CI / déploiement.
# =====================================================================

namespace :migration do
  desc 'Migrate existing data to Person-Based Architecture'
  task person_architecture: :environment do
    puts '🚀 Starting migration to Person-Based Architecture...'

    # Étape 1: Créer les données de référence
    puts "\n📋 Step 1: Creating reference data..."
    create_membership_types!
    create_subscription_plans!

    # Étape 2: Migrer les utilisateurs vers les personnes
    puts "\n👥 Step 2: Migrating users to people..."
    migrate_users_to_people!

    # Étape 3: Migrer les adhésions
    puts "\n🏛️ Step 3: Migrating memberships..."
    migrate_memberships!

    # Étape 4: Migrer les paiements
    puts "\n💰 Step 4: Migrating payments..."
    migrate_payments!

    # Étape 5: Migrer les carnets
    puts "\n📚 Step 5: Migrating book of entries..."
    migrate_book_of_entries!

    # Étape 6: Migrer les présences
    puts "\n📅 Step 6: Migrating attendances..."
    migrate_attendances!

    # Étape 7: Validation
    puts "\n✅ Step 7: Validating migration..."
    validate_migration!

    puts "\n🎉 Migration completed successfully!"
    puts '📊 Summary:'
    puts "  - People: #{Person.count}"
    puts "  - Users: #{User.count}"
    puts "  - Memberships: #{Membership.count}"
    puts "  - Payments: #{Payment.count}"
    puts "  - Book of entries: #{BookOfEntry.count}"
    puts "  - Attendances: #{Attendance.count}"
  end

  private

  def create_membership_types!
    puts '  Creating membership types...'
    MembershipType.create_default_types!
    puts "  ✅ Created #{MembershipType.count} membership types"
  end

  def create_subscription_plans!
    puts '  Creating subscription plans...'
    SubscriptionPlan.create_default_plans!
    puts "  ✅ Created #{SubscriptionPlan.count} subscription plans"
  end

  def migrate_users_to_people!
    migrated_count = 0

    User.includes(:person).find_each do |user|
      next if user.person.present? # Skip if already migrated

      creator = People::PersonCreator.new(
        first_name: user.first_name || 'Unknown',
        last_name: user.last_name || 'User',
        email: user.email,
        allow_blank_attributes: true
      )
      result = creator.call
      raise "Failed to create person for user ##{user.id}: #{result.message}" unless result.success?

      person = result.person
      # Preserve original timestamps
      person.update_columns(created_at: user.created_at, updated_at: user.updated_at)

      user.update!(person: person)
      migrated_count += 1
    end

    puts "  ✅ Migrated #{migrated_count} users to people"
  end

  def migrate_memberships!
    migrated_count = 0

    # Migrer les user_memberships existantes
    if defined?(UserMembership)
      UserMembership.find_each do |user_membership|
        next if user_membership.user.person.blank?

        # Déterminer le type d'adhésion
        membership_type = determine_membership_type(user_membership)

        # Vérifier s'il n'y a pas déjà une adhésion active
        existing_membership = Membership.find_by(
          person: user_membership.user.person,
          status: %i[active inactive]
        )

        unless existing_membership
          Membership.create!(
            person: user_membership.user.person,
            membership_type: membership_type,
            started_at: user_membership.created_at.to_date,
            ended_at: user_membership.created_at.to_date + 1.year,
            status: determine_membership_status(user_membership),
            first_joined_at: user_membership.created_at.to_date,
            created_at: user_membership.created_at,
            updated_at: user_membership.updated_at
          )
        end

        migrated_count += 1
      end
    end

    puts "  ✅ Migrated #{migrated_count} memberships"
  end

  def migrate_payments!
    migrated_count = 0

    Payment.find_each do |payment|
      next if payment.person.present? # Skip if already migrated

      # Trouver la personne associée
      person = find_person_for_payment(payment)
      next unless person

      # Créer les lignes de paiement si nécessaire
      if payment.order&.product_orders.present? && payment.payment_lines.empty?
        payment.order.product_orders.each do |product_order|
          item = determine_payment_item(product_order.product)
          next unless item

          # Vérifier si la ligne existe déjà
          existing_line = PaymentLine.find_by(
            payment: payment,
            item: item
          )

          next if existing_line

          PaymentLine.create!(
            payment: payment,
            item: item,
            amount_cents: calculate_amount_cents(product_order),
            description: "#{item.class.name} - #{product_order.product.product_name}"
          )
        end
      end

      # Mettre à jour le paiement
      payment.update!(
        person: person,
        recorded_by: User.first, # Fallback
        total_cents: payment.total_payment&.*(100).to_i,
        payment_method: map_payment_method(payment.payment_type)
      )

      migrated_count += 1
    end

    puts "  ✅ Migrated #{migrated_count} payments"
  end

  def migrate_book_of_entries!
    migrated_count = 0

    BookOfEntry.find_each do |book_of_entry|
      next if book_of_entry.person.present? # Skip if already migrated

      # Trouver la personne associée
      person = find_person_for_book_of_entry(book_of_entry)
      next unless person

      # Trouver le plan d'abonnement correspondant
      subscription_plan = determine_subscription_plan(book_of_entry.product)

      book_of_entry.update!(
        person: person,
        subscription_plan: subscription_plan,
        sessions_remaining: book_of_entry.sessions_remaining || 0,
        purchased_at: book_of_entry.created_at,
        expires_at: book_of_entry.created_at + 1.year
      )

      migrated_count += 1
    end

    puts "  ✅ Migrated #{migrated_count} book of entries"
  end

  def migrate_attendances!
    migrated_count = 0

    Attendance.find_each do |attendance|
      next if attendance.person.present? # Skip if already migrated

      # Trouver la personne associée
      person = find_person_for_attendance(attendance)
      next unless person

      # Vérifier s'il n'y a pas déjà une présence pour cette personne à cette date
      existing_attendance = Attendance.find_by(
        person: person,
        date: attendance.created_at.to_date
      )

      unless existing_attendance
        attendance.update!(
          person: person,
          date: attendance.created_at.to_date
        )
      end

      migrated_count += 1
    end

    puts "  ✅ Migrated #{migrated_count} attendances"
  end

  def validate_migration!
    puts '  Validating data integrity...'

    # Vérifier que tous les users ont une person
    users_without_person = User.where(person_id: nil).count
    puts "  Users without person: #{users_without_person}" if users_without_person.positive?

    # Vérifier que tous les paiements ont une person
    payments_without_person = Payment.where(person_id: nil).count
    puts "  Payments without person: #{payments_without_person}" if payments_without_person.positive?

    # Vérifier que toutes les adhésions ont une person
    memberships_without_person = Membership.where(person_id: nil).count
    puts "  Memberships without person: #{memberships_without_person}" if memberships_without_person.positive?

    puts '  ✅ Validation completed'
  end

  # Helper methods

  def determine_membership_type(_user_membership)
    # Logique pour déterminer le type d'adhésion
    # À adapter selon les données existantes
    MembershipType.find_by(category: :basic) || MembershipType.first
  end

  def determine_membership_status(_user_membership)
    # Logique pour déterminer le statut
    # À adapter selon les données existantes
    :active
  end

  def find_person_for_payment(payment)
    return payment.user.person if payment.user&.person

    # Fallback: chercher par email
    Person.find_by(email: payment.user&.email) if payment.user&.email
  end

  def find_person_for_book_of_entry(book_of_entry)
    return book_of_entry.user.person if book_of_entry.user&.person

    # Fallback: chercher par email
    Person.find_by(email: book_of_entry.user&.email) if book_of_entry.user&.email
  end

  def find_person_for_attendance(attendance)
    return attendance.user.person if attendance.user&.person

    # Fallback: chercher par email
    Person.find_by(email: attendance.user&.email) if attendance.user&.email
  end

  def determine_payment_item(product)
    # Logique pour déterminer l'item du paiement
    # À adapter selon les produits existants
    if product.product_name&.downcase&.include?('membership')
      MembershipType.first
    elsif product.product_name&.downcase&.include?('pack')
      SubscriptionPlan.find_by(duration: :pack10)
    else
      SubscriptionPlan.first
    end
  end

  def calculate_amount_cents(product_order)
    # Logique pour calculer le montant
    # À adapter selon les données existantes
    product_order.product.price_entries.order(created_at: :desc).first&.price_catalog&.price&.*(100).to_i
  end

  def determine_subscription_plan(product)
    # Logique pour déterminer le plan d'abonnement
    # À adapter selon les produits existants
    if product.product_name&.downcase&.include?('pack')
      SubscriptionPlan.find_by(duration: :pack10)
    else
      SubscriptionPlan.first
    end
  end

  def map_payment_method(payment_type)
    # Mapper les anciens types de paiement vers les nouveaux
    case payment_type&.to_s&.downcase
    when 'cash', 'espèces'
      :cash
    when 'card', 'carte'
      :sumup
    when 'check', 'chèque'
      :cheque
    when 'transfer', 'virement'
      :transfer
    else
      :cash
    end
  end
end
