# frozen_string_literal: true

# Population volumique et aléatoire : personnes, comptes web, adhésions, cotisations, paiements,
# présences, quelques revendications. Pas de gem Faker (compatible staging/production Docker).
puts "\n🎲 Population aléatoire (adhésions + cotisations + volume)..."

SEED_DEFAULT_PASSWORD = "password123".freeze unless defined?(SEED_DEFAULT_PASSWORD)

def seed_register_person(person_attributes, create_user: false, user_role: "web_visitor", created_by_admin: true)
  attrs = person_attributes.dup
  newsletter_flag = attrs.delete(:newsletter_subscribed)

  result = People::Register.new(
    person_params: attrs,
    newsletter_subscribed: newsletter_flag,
    newsletter_source: created_by_admin ? "admin" : "web",
    create_user_account: create_user,
    user_params: create_user ? {
      email_address: attrs[:email],
      password: SEED_DEFAULT_PASSWORD,
      system_role: user_role,
      created_by_admin: created_by_admin,
      cgu: true,
      privacy_policy: true
    } : {},
    create_membership: false
  ).call

  raise "Seed error: #{result.message}" unless result.success?

  result.person
end

def seed_record_donation!(person, total_cents:, recorded_by:, notes: "Donation")
  res = People::PaymentRecorder.new(
    person: person,
    recorded_by: recorded_by,
    payment_method: "cash",
    status: "success",
    notes: notes,
    total_cents: total_cents,
    payment_lines: [
      {
        item_type: "Donation",
        amount_cents: total_cents,
        description: "Donation"
      }
    ]
  ).call
  raise "seed donation: #{res.message}" unless res.success?

  res
end

DEFAULT_POP = SEED_LEAN ? 45 : 140
POPULATION = ENV.fetch("SEED_POPULATION_COUNT", DEFAULT_POP.to_s).to_i.clamp(1, 15_000)
SEED_RANDOM_SEED = ENV.fetch("SEED_RANDOM_SEED", "lecircographe-seed").hash.abs # stable défaut
RNG = Random.new(SEED_RANDOM_SEED)

FIRST_NAMES = %w[
  Alexandre Marie Thomas Camille Julien Sophie Nicolas Julie Antoine Claire Pierre Émilie Maxime Léa Romain Chloé
  Baptiste Manon Hugo Emma Lucas Gabriel Sarah Louis Océane Arthur Lola Ethan Inès Noah Zoé Liam Mia Léon Luna
  Raphaël Alice Paul Rose Gabin Anna Timéo Louise Nolan Jade Enzo Agathe Maël Naël Kylian Mila Axel Eva Aaron Nina
].freeze

LAST_NAMES = %w[
  Martin Bernard Dubois Thomas Robert Richard Petit Durand Moreau Laurent Simon Michel Lefebvre Leroy Roux David
  Bertrand Rousseau Vincent Fournier Girard Bonnet Dupont Lambert Fontaine Renaud Blanc Colin Marchand Fabre Pons
].freeze

CITIES = %w[
  Paris Lyon Marseille Toulouse Nice Nantes Strasbourg Montpellier Bordeaux Lille Rennes Grenoble Dijon Tours Reims
].freeze

STREETS = %w[Victor-Hugo République Gambetta Clemenceau Pasteur Alsace-Lorraine].freeze

PAYMENT_METHODS_MEMBERSHIP = %w[cash card cheque transfer].freeze

NOTES_SNIPPETS = [
  "Inscription porte ouverte",
  "Passage par un bénévole",
  "CRM — import liste papier",
  "Essai cours découverte",
  "Renouvellement automatique",
  "Tarif solidarité",
  "Mineur — représentant légal OK"
].freeze

basic_membership = MembershipType.find_by(category: "basic")
circus_types = MembershipType.where(category: "circus").order(price_cents: :desc)
circus_full_membership = circus_types.first
circus_reduced_membership = circus_types.last

admin_user = User.find_by(system_role: "admin")
raise "seed populate: admin introuvable" if admin_user.nil?

formula_pack10 = ContributionFormula.find_by!(duration: "pack10")
formula_trimester = ContributionFormula.find_by!(duration: "trimester")
formula_annual = ContributionFormula.find_by!(duration: "annual")

used_emails = {}

def seed_build_email_local(fn, ln, index)
  raw = ActiveSupport::Inflector.transliterate("#{fn}.#{ln}.#{index}")
  raw.downcase.gsub(/[^a-z0-9]+/, ".").squeeze(".").gsub(/^\.|\.$/, "").presence || "person.#{index}"
end

POPULATION.times do |i|
  fn = FIRST_NAMES.sample(random: RNG)
  ln = LAST_NAMES.sample(random: RNG)
  base = seed_build_email_local(fn, ln, i)
  email = "#{base}@seed.example.com"
  while used_emails.key?(email) || Person.exists?(email: email)
    email = "#{base}.#{format('%06x', RNG.rand(0xffffff))}@seed.example.com"
  end
  used_emails[email] = true

  birth_year = RNG.rand(1955..2012)
  is_minor = birth_year > (Date.current.year - 18)

  create_web = RNG.rand < 0.72
  role = case RNG.rand
         when 0..0.92 then "web_visitor"
         when 0.92..0.97 then "volunteer"
         else "web_visitor"
         end

  person = seed_register_person(
    {
      first_name: fn,
      last_name: ln,
      email: email,
      phone: "+33 6 #{RNG.rand(10..99)} #{RNG.rand(10..99)} #{RNG.rand(10..99)} #{RNG.rand(10..99)}",
      address: "#{RNG.rand(1..180)} rue #{STREETS.sample(random: RNG)}",
      zip_code: format("%05d", RNG.rand(10_000..99_999)),
      town: CITIES.sample(random: RNG),
      country: "France",
      birth_date: Date.new(birth_year, RNG.rand(1..12), RNG.rand(1..28)),
      newsletter_subscribed: RNG.rand < 0.4,
      get_involved: RNG.rand < 0.35,
      image_rights: RNG.rand < 0.85,
      is_minor: is_minor,
      notes: NOTES_SNIPPETS.sample(random: RNG)
    },
    create_user: create_web,
    user_role: role,
    created_by_admin: true
  )

  roll = RNG.rand

  # ~7 % don seul (sans adhésion)
  if roll < 0.07
    seed_record_donation!(
      person,
      total_cents: [ 300, 500, 1_000, 2_000 ].sample(random: RNG),
      recorded_by: admin_user,
      notes: "Don seed aléatoire"
    )
    next
  end

  # ~6 % personne CRM sans adhésion ni paiement
  next if roll < 0.13

  membership_type = case RNG.rand
                    when 0..0.38 then basic_membership
                    when 0.38..0.69 then circus_reduced_membership
                    else circus_full_membership
                    end

  pay_m = PAYMENT_METHODS_MEMBERSHIP.sample(random: RNG)

  res_m = People::MembershipCreator.new(
    person: person.reload,
    membership_type_id: membership_type.id,
    payment_method: pay_m,
    recorded_by_id: admin_user.id,
    donation_cents: (RNG.rand < 0.12 ? [ 200, 300, 500 ].sample(random: RNG) : nil)
  ).call

  unless res_m.success?
    puts "  ⚠️ Adhésion ignorée #{person.email}: #{res_m.message}"
    next
  end

  person.reload
  next unless membership_type.circus?

  # Cotisation cirque : ~70 % des profils cirque
  next if RNG.rand > 0.70

  formula = case RNG.rand
            when 0..0.48 then formula_pack10
            when 0.48..0.78 then formula_trimester
            else formula_annual
            end

  donation_extra = RNG.rand < 0.14 ? RNG.rand(1..15) * 100 : nil

  cc = People::ContributionCreator.new(
    person: person,
    contribution_formula_id: formula.id,
    payment_method: PAYMENT_METHODS_MEMBERSHIP.sample(random: RNG),
    recorded_by_id: admin_user.id,
    donation_cents: donation_extra
  ).call

  unless cc.success?
    next
  end

  contribution = cc.contribution.reload

  # États variés (pack10 / trimestre)
  if formula.duration == "pack10" && contribution.active?
    case RNG.rand
    when 0..0.12
      RNG.rand(2..6).times { contribution.reload.use_session! }
    when 0.12..0.18
      contribution.suspend!(reason: "Seed — suspension aléatoire")
    end
  elsif formula.duration == "trimester" && contribution.active? && RNG.rand < 0.15
    contribution.update!(expires_at: 120.days.ago, status: :expired)
  end
end

# --- Revendications de compte (quelques dossiers) ---
claim_n = 0
claim_scope = Person.without_user_account
if claim_scope.exists?
  claim_n = [ (POPULATION / 25).clamp(2, 80), claim_scope.count ].min
  claim_scope.order(Arel.sql("RANDOM()")).limit(claim_n).each do |p|
    AccountClaim.where(person_id: p.id).delete_all
    AccountClaim.create!(
      person: p,
      expires_at: RNG.rand(1..20).days.from_now,
      status: :pending
    )
  end
end

# --- Listes de présence + présences (volume) ---
list_types = AttendanceList.list_types.keys
statuses = AttendanceList.statuses.keys

lists = 12.times.map do |j|
  AttendanceList.create!(
    name: "Liste seed ##{j + 1} — #{NOTES_SNIPPETS.sample(random: RNG)}",
    list_type: list_types.sample(random: RNG),
    status: statuses.sample(random: RNG),
    start_date: RNG.rand(60).days.ago.to_date,
    end_date: RNG.rand(30).days.from_now.to_date
  )
end

person_ids = Person.pluck(:id)
target_presences = [ POPULATION * 6, 8000 ].min
created_pres = 0
attempts = 0
max_attempts = target_presences * 8

while created_pres < target_presences && attempts < max_attempts
  attempts += 1
  pid = person_ids.sample(random: RNG)
  day = RNG.rand(100).days.ago.to_date
  next if Attendance.exists?(person_id: pid, date: day)

  begin
    Attendance.create!(
      person_id: pid,
      attendance_list_id: lists.sample(random: RNG).id,
      date: day
    )
    created_pres += 1
  rescue ActiveRecord::RecordInvalid
    next
  end
end

# --- Intérêt événements (présences liées aux Event seed) ---
Event.find_each do |event|
  sample_size = [ RNG.rand(8..35), person_ids.size ].min
  person_ids.sample(sample_size, random: RNG).each do |pid|
    next if Attendance.exists?(person_id: pid, event_id: event.id)

    Attendance.create!(
      person_id: pid,
      event_id: event.id,
      date: event.date&.to_date || Date.current
    )
  rescue ActiveRecord::RecordInvalid
    next
  end
end

puts "  ✅ Grain RNG=#{SEED_RANDOM_SEED} — #{POPULATION} profils, présences listes=#{created_pres}, revendications=#{claim_n}"
puts "     Comptes web seed : mot de passe #{SEED_DEFAULT_PASSWORD} pour *@seed.example.com"
