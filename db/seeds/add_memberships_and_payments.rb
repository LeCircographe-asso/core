# Seed pour ajouter des adhésions et paiements aux personnes existantes
puts "\n💰 Adding memberships and payments to existing people..."

# Récupérer les types d'adhésion
basic_membership = MembershipType.find_by(category: "basic")
circus_types = MembershipType.where(category: "circus").order(price_cents: :desc)
circus_full_membership = circus_types.first
circus_reduced_membership = circus_types.last

# Récupérer les comptes système
admin_user = User.find_by(system_role: "admin")
volunteer_user = User.find_by(system_role: "volunteer")

# Pour chaque personne qui a déjà une adhésion (créée dans sample_people.rb), on supprime et recrée avec la bonne logique
Person.includes(:memberships).where.not(memberships: { id: nil }).find_each do |person|
  # Supprimer les anciennes adhésions (créées manuellement sans paiements)
  person.memberships.destroy_all

  # Déterminer le type d'adhésion en fonction du nom ou de la situation
  membership_type = case person.email
  when /alice/
    basic_membership
  when /bob/
    circus_full_membership
  when /charlie|étudiant|student/
    circus_reduced_membership
  else
    # Distribution aléatoire équitable
    rand_case = person.id % 4
    case rand_case
    when 0
      basic_membership
    when 1
      circus_full_membership
    when 2
      circus_reduced_membership
    else
      nil # Pas d'adhésion
    end
  end

  # Créer l'adhésion avec la nouvelle logique (créera le paiement et le numéro automatiquement)
  if membership_type
    begin
      result = person.create_membership!(
        membership_type,
        payment_method: :cash,
        recorded_by: admin_user
      )
      puts "  ✅ #{person.full_name}: #{membership_type.name} - Numéro: #{person.reload.member_number}"
    rescue => e
      puts "  ❌ #{person.full_name}: Erreur - #{e.message}"
    end
  end
end

# Pour les personnes sans adhésion, en créer pour 50% d'entre elles
Person.left_joins(:memberships).where(memberships: { id: nil }).find_each.with_index do |person, index|
  next if index % 2 == 0 # Skip une personne sur deux

  membership_type = case index % 4
  when 0
    basic_membership
  when 1
    circus_full_membership
  when 2
    circus_reduced_membership
  else
    nil
  end

  if membership_type
    begin
      result = person.create_membership!(
        membership_type,
        payment_method: :cash,
        recorded_by: admin_user
      )
      puts "  ✅ #{person.full_name}: #{membership_type.name} - Numéro: #{person.reload.member_number}"
    rescue => e
      puts "  ❌ #{person.full_name}: Erreur - #{e.message}"
    end
  end
end

puts "\n🎉 Memberships and payments added successfully!"
puts "📊 Summary:"
puts "  - #{Membership.count} adhésions total"
puts "  - #{Membership.where(status: :active).count} adhésions actives"
puts "  - #{Payment.count} paiements total"
puts "  - #{Payment.where(status: :success).count} paiements réussis"
puts "  - #{Person.where.not(member_number: nil).count} personnes avec numéro d'adhérent"
