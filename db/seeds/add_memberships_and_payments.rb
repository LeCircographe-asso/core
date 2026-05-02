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
  when /emma\.complexe/
    basic_membership # upgrade Basic -> Cirque plus bas dans ce fichier
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
      result = People::MembershipCreator.new(
        person: person,
        membership_type_id: membership_type.id,
        payment_method: "cash",
        recorded_by_id: admin_user&.id
      ).call

      if result.success?
        puts "  ✅ #{person.full_name}: #{membership_type.name} - Numéro: #{person.reload.member_number}"
      else
        puts "  ❌ #{person.full_name}: Erreur - #{result.message}"
      end
    rescue => e
      puts "  ❌ #{person.full_name}: Erreur - #{e.message}"
    end
  end
end

# Pour les personnes sans adhésion, en créer pour 50% d'entre elles
Person.left_joins(:memberships).where(memberships: { id: nil }).find_each.with_index do |person, index|
  # Cas métier : prospect volontairement sans adhésion (don possible, pas de cotisation cirque).
  next if person.email.to_s.match?(/diana\.prospect@/)

  # Frank : adhésion Cirque obligatoire pour les scénarios cotisation (créé dans sample_people sans adhésion).
  membership_type = if person.email.to_s.match?(/frank\.newcomer@/)
    circus_full_membership
  else
    next if index % 2 == 0 # Skip une personne sur deux

    case index % 4
    when 0
      basic_membership
    when 1
      circus_full_membership
    when 2
      circus_reduced_membership
    else
      nil
    end
  end

  if membership_type
    begin
      result = People::MembershipCreator.new(
        person: person,
        membership_type_id: membership_type.id,
        payment_method: "cash",
        recorded_by_id: admin_user&.id
      ).call

      if result.success?
        puts "  ✅ #{person.full_name}: #{membership_type.name} - Numéro: #{person.reload.member_number}"
      else
        puts "  ❌ #{person.full_name}: Erreur - #{result.message}"
      end
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

# -----------------------------------------------------------------------------
# Cas métier larges (docs/glossary.md, docs/domain/business_logic.md)
# Comptes : scenario.*@example.com -> password123 si compte web ; systeme inchangé (admin.rb).
# -----------------------------------------------------------------------------
super_admin_user = User.find_by(system_role: "super_admin")
raise "seed: super_admin introuvable" if super_admin_user.nil?
raise "seed: admin introuvable" if admin_user.nil?

formula_pack10 = ContributionFormula.find_by!(duration: "pack10")
formula_day = ContributionFormula.find_by!(duration: "day")
formula_trimester = ContributionFormula.find_by!(duration: "trimester")
formula_annual = ContributionFormula.find_by!(duration: "annual")

def seed_ensure_circus_only!(person, circus_type, recorded_by_id:)
  person.memberships.destroy_all
  res = People::MembershipCreator.new(
    person: person,
    membership_type_id: circus_type.id,
    payment_method: "cash",
    recorded_by_id: recorded_by_id
  ).call
  raise "seed circus: #{res.message}" unless res.success?

  person.reload.current_membership
end

alice_story = Person.find_by!(email: "alice.cirque@example.com")
alice_story.upgrade_membership!(
  circus_reduced_membership,
  recorded_by: admin_user,
  payment_method: :cash
)

bob_story = Person.find_by!(email: "bob.basique@example.com")
ann_res = People::ContributionCreator.new(
  person: bob_story,
  contribution_formula_id: formula_annual.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id,
  donation_cents: 500
).call
raise "seed bob annual: #{ann_res.message}" unless ann_res.success?

charlie_story = Person.find_by!(email: "charlie.etudiant@example.com")
pack_ch = People::ContributionCreator.new(
  person: charlie_story,
  contribution_formula_id: formula_pack10.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed charlie pack: #{pack_ch.message}" unless pack_ch.success?
3.times { pack_ch.contribution.reload.use_session! }

diana_story = Person.find_by!(email: "diana.prospect@example.com")
diana_story.create_donation!(500, recorded_by: admin_user, payment_method: :cash, notes: "Don prospect (sans adhésion)")

emma_story = Person.find_by!(email: "emma.complexe@example.com")
emma_story.upgrade_membership!(
  circus_full_membership,
  recorded_by: admin_user,
  payment_method: :cash
)

frank_story = Person.find_by!(email: "frank.newcomer@example.com")
fr_pack = People::ContributionCreator.new(
  person: frank_story,
  contribution_formula_id: formula_pack10.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed frank pack: #{fr_pack.message}" unless fr_pack.success?

up_fr = People::ContributionUpgrader.new(
  person: frank_story,
  from_contribution_id: fr_pack.contribution.id,
  to_formula_id: formula_trimester.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed frank upgrade pack->trim: #{up_fr.message}" unless up_fr.success?

gaspard = seed_register_person(
  {
    first_name: "Gaspard",
    last_name: "Packdix",
    email: "scenario.pack10@example.com",
    phone: "+33 6 10 00 00 01",
    address: "1 Rue du Trapèze",
    zip_code: "75001",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1991, 4, 4),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: true,
    notes: "Scenario métier : pack10 sans compte web"
  },
  create_user: false
)
seed_ensure_circus_only!(gaspard, circus_full_membership, recorded_by_id: admin_user.id)
gp = People::ContributionCreator.new(
  person: gaspard,
  contribution_formula_id: formula_pack10.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed gaspard: #{gp.message}" unless gp.success?
3.times { gp.contribution.reload.use_session! }

ines = seed_register_person(
  {
    first_name: "Inès",
    last_name: "Offerte",
    email: "scenario.offert@example.com",
    phone: "+33 6 10 00 00 02",
    address: "2 Rue de la Jongle",
    zip_code: "75002",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1987, 7, 7),
    newsletter_subscribed: true,
    get_involved: false,
    image_rights: true,
    notes: "Scenario métier : journée offerte (super admin + motif)"
  },
  create_user: true
)
seed_ensure_circus_only!(ines, circus_reduced_membership, recorded_by_id: admin_user.id)
off_res = People::ContributionCreator.new(
  person: ines,
  contribution_formula_id: formula_day.id,
  payment_method: "offered",
  recorded_by_id: super_admin_user.id,
  offer_reason: "Solidarité — seed"
).call
raise "seed offert: #{off_res.message}" unless off_res.success?

julien = seed_register_person(
  {
    first_name: "Julien",
    last_name: "Donseul",
    email: "scenario.don@example.com",
    phone: "+33 6 10 00 00 03",
    address: "3 Rue du Saltimbanque",
    zip_code: "75003",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1975, 1, 1),
    newsletter_subscribed: false,
    get_involved: false,
    image_rights: true,
    notes: "Scenario métier : don seul"
  },
  create_user: false
)
julien.create_donation!(500, recorded_by: admin_user, payment_method: :cash, notes: "Don seul seed")

karine = seed_register_person(
  {
    first_name: "Karine",
    last_name: "Upgrade",
    email: "scenario.upgrade.cotisation@example.com",
    phone: "+33 6 10 00 00 04",
    address: "4 Rue des Arceaux",
    zip_code: "75004",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1993, 9, 9),
    newsletter_subscribed: true,
    get_involved: true,
    image_rights: true,
    notes: "Scenario métier : trimestre -> annuel (crédit)"
  },
  create_user: true
)
seed_ensure_circus_only!(karine, circus_full_membership, recorded_by_id: admin_user.id)
trk = People::ContributionCreator.new(
  person: karine,
  contribution_formula_id: formula_trimester.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed karine trim: #{trk.message}" unless trk.success?

up_k = People::ContributionUpgrader.new(
  person: karine,
  from_contribution_id: trk.contribution.id,
  to_formula_id: formula_annual.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed karine up: #{up_k.message}" unless up_k.success?

laura = seed_register_person(
  {
    first_name: "Laura",
    last_name: "Membredon",
    email: "scenario.membre.don@example.com",
    phone: "+33 6 10 00 00 05",
    address: "5 Rue des Équilibristes",
    zip_code: "75005",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1999, 2, 2),
    newsletter_subscribed: true,
    get_involved: true,
    image_rights: true,
    notes: "Scenario métier : adhésion basic + don même paiement"
  },
  create_user: true
)
laura.memberships.destroy_all
laura.create_membership!(basic_membership, recorded_by: admin_user, payment_method: :cash, donation_cents: 500)

michel = seed_register_person(
  {
    first_name: "Michel",
    last_name: "Bascule",
    email: "scenario.cirque.plein.reduit@example.com",
    phone: "+33 6 10 00 00 06",
    address: "6 Rue du Fil",
    zip_code: "75006",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1982, 3, 3),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: true,
    notes: "Scenario métier : Cirque plein -> Cirque réduit (plein tarif)"
  },
  create_user: false
)
seed_ensure_circus_only!(michel, circus_full_membership, recorded_by_id: admin_user.id)
michel.upgrade_membership!(
  circus_reduced_membership,
  recorded_by: admin_user,
  payment_method: :cash
)

sophie = seed_register_person(
  {
    first_name: "Sophie",
    last_name: "Expiree",
    email: "scenario.adhesion.expiree@example.com",
    phone: "+33 6 10 00 00 07",
    address: "7 Rue de la Lune",
    zip_code: "75007",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1994, 6, 6),
    newsletter_subscribed: true,
    get_involved: false,
    image_rights: true,
    notes: "Scenario métier : adhésion cirque expirée (historique)"
  },
  create_user: true
)
seed_ensure_circus_only!(sophie, circus_reduced_membership, recorded_by_id: admin_user.id)
m = sophie.memberships.last
m.update!(started_at: 3.years.ago, ended_at: 1.year.ago - 1.day, status: :expired)

yann = seed_register_person(
  {
    first_name: "Yann",
    last_name: "Enattente",
    email: "scenario.adhesion.pending@example.com",
    phone: "+33 6 10 00 00 08",
    address: "8 Rue du Chapiteau",
    zip_code: "75008",
    town: "Paris",
    country: "France",
    birth_date: Date.new(2001, 1, 11),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: true,
    notes: "Scenario métier : adhésion en attente (paiement à confirmer)"
  },
  create_user: false
)
yann.memberships.destroy_all
pend = yann.memberships.create!(
  membership_type: basic_membership,
  started_at: Date.current,
  ended_at: Date.current + 1.year,
  status: :pending,
  first_joined_at: nil
)
yann.payments.create!(
  total_cents: basic_membership.price_cents,
  payment_method: :cheque,
  status: :pending,
  recorded_by: admin_user,
  notes: "Chèque en attente — seed scénario pending"
).tap do |pay|
  pay.payment_lines.create!(
    item_type: "Membership",
    item_id: pend.id,
    amount_cents: basic_membership.price_cents,
    description: "Adhésion basic — en attente encaissement"
  )
end

puts "  📌 Cas métier seed : Alice Basic→Cirque réduit ; Bob annuel+don ; Charlie pack10 usé ; Diana don sans adhésion ; Emma Basic→Cirque plein ; Frank pack10→trimestre ; scenario.* (offert, don seul, trim→annuel, basic+don, plein→réduit, expirée, pending)."
