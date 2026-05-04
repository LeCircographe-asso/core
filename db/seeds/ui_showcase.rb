# frozen_string_literal: true

# États UI supplémentaires pour parcourir badges / listes / fiches admin.
# Comptes web : scenario.ui.*@example.com → password123 (sauf mentions sans User).
puts "\n🎭 Palette UI (états annexes métier)..."

basic_membership = MembershipType.find_by(category: "basic")
circus_types = MembershipType.where(category: "circus").order(price_cents: :desc)
circus_full_membership = circus_types.first
circus_reduced_membership = circus_types.last

admin_user = User.find_by(system_role: "admin")
formula_pack10 = ContributionFormula.find_by!(duration: "pack10")
formula_trimester = ContributionFormula.find_by!(duration: "trimester")

raise "seed ui_showcase: admin introuvable" if admin_user.nil?

# ----- Paiements : méthodes + annulé -----
ui_cb = seed_register_person(
  {
    first_name: "Clara",
    last_name: "Cartebleue",
    email: "scenario.ui.paiement.cb@example.com",
    phone: "+33 6 20 00 00 01",
    address: "10 Rue de la Piste",
    zip_code: "75010",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1989, 4, 4),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: true,
    notes: "UI — paiement adhésion par carte"
  },
  create_user: true
)
res_cb = People::MembershipCreator.new(
  person: ui_cb.reload,
  membership_type_id: basic_membership.id,
  payment_method: "card",
  recorded_by_id: admin_user.id
).call
raise "seed ui CB: #{res_cb.message}" unless res_cb.success?

ui_bank = seed_register_person(
  {
    first_name: "Boris",
    last_name: "Virement",
    email: "scenario.ui.paiement.virement@example.com",
    phone: "+33 6 20 00 00 02",
    address: "11 Avenue du Fil",
    zip_code: "75011",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1978, 8, 18),
    newsletter_subscribed: true,
    get_involved: false,
    image_rights: true,
    notes: "UI — paiement adhésion par virement"
  },
  create_user: true
)
res_tr = People::MembershipCreator.new(
  person: ui_bank.reload,
  membership_type_id: circus_reduced_membership.id,
  payment_method: "transfer",
  recorded_by_id: admin_user.id
).call
raise "seed ui virement: #{res_tr.message}" unless res_tr.success?

ui_cancel = seed_register_person(
  {
    first_name: "Nora",
    last_name: "Annulee",
    email: "scenario.ui.paiement.annule@example.com",
    phone: "+33 6 20 00 00 03",
    address: "12 Rue du Volant",
    zip_code: "75012",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1996, 2, 2),
    newsletter_subscribed: false,
    get_involved: false,
    image_rights: true,
    notes: "UI — paiement d'adhésion annulé (badge annulé)"
  },
  create_user: false
)
res_can = People::MembershipCreator.new(
  person: ui_cancel.reload,
  membership_type_id: basic_membership.id,
  payment_method: "cheque",
  recorded_by_id: admin_user.id
).call
raise "seed ui annulé: #{res_can.message}" unless res_can.success?

cancel_res = People::PaymentCanceller.new(
  payment: res_can.payment,
  deleted_by_id: admin_user.id,
  reason: "Scénario seed — démo UI liste paiements"
).call
raise "seed ui PaymentCanceller: #{cancel_res.message}" unless cancel_res.success?

# ----- Cotisation : expirée + pack suspendu -----
ui_expire = seed_register_person(
  {
    first_name: "Eva",
    last_name: "Trimestresse",
    email: "scenario.ui.cotisation.expiree@example.com",
    phone: "+33 6 20 00 00 04",
    address: "13 Rue des Cercles",
    zip_code: "75013",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1984, 11, 11),
    newsletter_subscribed: true,
    get_involved: true,
    image_rights: true,
    notes: "UI — cotisation trimestre statut expirée"
  },
  create_user: true
)
seed_ensure_circus_only!(ui_expire.reload, circus_full_membership, recorded_by_id: admin_user.id)

ex_trim = People::ContributionCreator.new(
  person: ui_expire,
  contribution_formula_id: formula_trimester.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed ui trim expired: #{ex_trim.message}" unless ex_trim.success?

ex_trim.contribution.update!(
  expires_at: 90.days.ago,
  status: :expired
)

ui_suspend = seed_register_person(
  {
    first_name: "Sam",
    last_name: "Packpause",
    email: "scenario.ui.pack10.suspendu@example.com",
    phone: "+33 6 20 00 00 05",
    address: "14 Rue du Trapèze",
    zip_code: "75014",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1990, 5, 5),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: true,
    notes: "UI — pack10 suspendu (badge / liste cotisations)"
  },
  create_user: true
)
seed_ensure_circus_only!(ui_suspend.reload, circus_full_membership, recorded_by_id: admin_user.id)

sp = People::ContributionCreator.new(
  person: ui_suspend,
  contribution_formula_id: formula_pack10.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed ui pack suspend: #{sp.message}" unless sp.success?

sp.contribution.suspend!(reason: "Blocage carte — seed UI showcase")

ui_epuise = seed_register_person(
  {
    first_name: "Léo",
    last_name: "Dixsur",
    email: "scenario.ui.pack10.epuise@example.com",
    phone: "+33 6 20 00 00 06",
    address: "15 Rue des Jongleurs",
    zip_code: "75015",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1992, 12, 12),
    newsletter_subscribed: true,
    get_involved: false,
    image_rights: true,
    notes: "UI — pack10 entièrement consommé (0 séances)"
  },
  create_user: false
)
seed_ensure_circus_only!(ui_epuise.reload, circus_reduced_membership, recorded_by_id: admin_user.id)

ep = People::ContributionCreator.new(
  person: ui_epuise,
  contribution_formula_id: formula_pack10.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed ui pack épuisé: #{ep.message}" unless ep.success?

10.times do
  ep.contribution.reload
  break if ep.contribution.status == "consumed"

  ep.contribution.use_session!
end

# ----- Adhésion inactive uniquement (pas d’actif courant pour la fiche) -----
ui_hist = seed_register_person(
  {
    first_name: "Hugo",
    last_name: "Historique",
    email: "scenario.ui.adhesion.inactive@example.com",
    phone: "+33 6 20 00 00 07",
    address: "16 Rue du Chapiteau",
    zip_code: "75016",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1981, 1, 19),
    newsletter_subscribed: false,
    get_involved: false,
    image_rights: true,
    notes: "UI — ancienne adhésion inactive (upgrade simulé côté data)"
  },
  create_user: true
)
res_hist = People::MembershipCreator.new(
  person: ui_hist.reload,
  membership_type_id: basic_membership.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call
raise "seed ui hist: #{res_hist.message}" unless res_hist.success?

old_m = res_hist.membership
old_m.update_columns(status: Membership.statuses.fetch("inactive"), ended_at: 6.months.ago, started_at: 18.months.ago)

People::MembershipCreator.new(
  person: ui_hist.reload,
  membership_type_id: circus_reduced_membership.id,
  payment_method: "cash",
  recorded_by_id: admin_user.id
).call.tap do |second|
  raise "seed ui hist 2: #{second.message}" unless second.success?
  second.membership.update!(status: :inactive, ended_at: 1.week.ago, started_at: 6.months.ago + 1.day)
end

# ----- Mineur -----
seed_register_person(
  {
    first_name: "Milo",
    last_name: "Mineurui",
    email: "scenario.ui.personne.mineure@example.com",
    phone: "+33 6 20 00 00 08",
    address: "17 Rue du Lâcher",
    zip_code: "75017",
    town: "Paris",
    country: "France",
    birth_date: Date.new(Date.current.year - 12, 6, 1),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: false,
    is_minor: true,
    notes: "UI — fiche personne mineure"
  },
  create_user: true
)

# ----- Revendication de compte (pending) -----
ui_claim_person = seed_register_person(
  {
    first_name: "Candice",
    last_name: "Revendication",
    email: "scenario.ui.compte.revendication@example.com",
    phone: "+33 6 20 00 00 09",
    address: "18 Rue du Portail",
    zip_code: "75018",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1983, 3, 3),
    newsletter_subscribed: true,
    get_involved: false,
    image_rights: true,
    notes: "UI — dossier avec demande de rattachement compte (pending)"
  },
  create_user: false
)
AccountClaim.where(person_id: ui_claim_person.id).delete_all
AccountClaim.create!(
  person: ui_claim_person,
  expires_at: 7.days.from_now,
  status: :pending
)

# ----- Listes de présence (types + statuts) -----
AttendanceList.create!(
  name: "Formation — liste ouverte (seed UI)",
  list_type: :training,
  status: :open,
  start_date: Date.current,
  end_date: Date.current + 1.week
)

AttendanceList.create!(
  name: "Événement — liste fermée (seed UI)",
  list_type: :event,
  status: :close,
  start_date: 3.days.ago.to_date,
  end_date: 2.days.ago.to_date
)

AttendanceList.create!(
  name: "Réunion — archivée (seed UI)",
  list_type: :meeting,
  status: :archived,
  start_date: 1.month.ago.to_date,
  end_date: 1.month.ago.to_date + 2.days
)

puts '  ✅ scenario.ui.* — CB, virement, paiement annulé, cotisation expirée, pack suspendu / épuisé,' \
     " doubles adhésions inactives, mineur, account_claim pending, listes présence ouvert·fermé·archivé."
puts "     Connexion démo web : tout *@example.com → #{SEED_DEFAULT_PASSWORD} sauf Nora (sans User)."
