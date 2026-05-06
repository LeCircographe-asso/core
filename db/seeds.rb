# Seeds — données de référence + population aléatoire volumique.
# Voir docs/glossary.md pour le vocabulaire canonique.

SEED_VERBOSE = ActiveModel::Type::Boolean.new.cast(ENV["SEED_VERBOSE"])
SEED_FAST_TEST = ActiveModel::Type::Boolean.new.cast(ENV["SEED_FAST_TEST"])
SEED_LEAN = ActiveModel::Type::Boolean.new.cast(ENV["SEED_LEAN"])
SEED_TICK_SECONDS = ENV.fetch("SEED_TICK_SECONDS", "1.6").to_f.clamp(0.25, 5.0)

SYSTEM_ACCOUNTS = [
  ["Super Admin", "super-admin@rails.com", "123456"],
  ["Admin", "admin@rails.com", "123456"],
  ["Volunteer", "volunteer@rails.com", "123456"]
].freeze

SEED_STEPS = [
  ["creation des comptes systeme", "admin.rb"],
  ["catalogue des types d'adhesion", "membership_types.rb"],
  ["catalogue des formules de cotisation", "contribution_formulas.rb"],
  ["creation des evenements", "events.rb"],
  ["population aleatoire (users, adhesions, cotisations)", "populate.rb"]
].freeze

SEED_LOGO_BRAILLE_FULL = [
  "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡶⠿⠿⠷⣶⣄⠀⠀⠀⠀⠀",
  "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠁⠀⠀⢀⣀⡀⠙⣷⡀⠀⠀⠀",
  "⠀⠀⠀⡀⠀⠀⠀⠀⠀⢠⣿⠁⠀⠀⠀⠘⠿⠃⠀⢸⣿⣿⣿⣿",
  "⠀⣠⡿⠛⢷⣦⡀⠀⠀⠈⣿⡄⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⠟",
  "⢰⡿⠁⠀⠀⠙⢿⣦⣤⣤⣼⣿⣄⠀⠀⠀⠀⠀⢴⡟⠛⠋⠁⠀",
  "⣿⠇⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠈⣿⡀⠀⠀⠀",
  "⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠀⠀⠀",
  "⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡇⠀⠀⠀",
  "⠸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡿⠀⠀⠀⠀",
  "⠀⠹⣷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣰⡿⠁⠀⠀⠀⠀",
  "⠀⠀⠀⠉⠙⠛⠿⠶⣶⣶⣶⣶⣶⠶⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀"
].freeze

def seed_logo_braille_scaled(horizontal_step: ENV.fetch("SEED_LOGO_HORIZONTAL_STEP", "2").to_i.clamp(1..4))
  SEED_LOGO_BRAILLE_FULL.map do |row|
    row.chars.each_slice(horizontal_step).map(&:first).join
  end
end

def print_seed_banner
  seed_logo_braille_scaled.each { |line| puts line }
  puts "\nLe Circographe — initialisation des données de référence\n\n"
end

def render_progress(current, total, label, action:)
  width = 32
  filled = (current * width / total.to_f).round
  bar = ("#" * filled).ljust(width, "-")
  percent = (current * 100 / total.to_f).round

  print "\r\e[2K[#{bar}] #{percent.to_s.rjust(3)}%  #{action}: #{label}"
  puts if current == total
end

def render_step(current, total, label, started_at)
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  render_progress(current, total, "#{label} (#{format('%.1fs', elapsed)})", action: "upload")
end

def reset_application_data!
  skip_tables = %w[schema_migrations ar_internal_metadata sqlite_sequence]
  conn = ActiveRecord::Base.connection
  deleted = 0

  conn.disable_referential_integrity do
    (conn.tables - skip_tables).each do |table|
      quoted = conn.quote_table_name(table)
      count = conn.select_value("SELECT COUNT(*) FROM #{quoted}").to_i
      next if count.zero?

      conn.execute("DELETE FROM #{quoted}")
      deleted += count
    end
  end

  deleted
end

def load_seed_file(filename)
  if SEED_VERBOSE
    load Rails.root.join("db", "seeds", filename)
  else
    original_stdout = $stdout
    muted_stdout = File.open(File::NULL, "w")

    begin
      $stdout = muted_stdout
      load Rails.root.join("db", "seeds", filename)
    ensure
      $stdout = original_stdout
      muted_stdout.close
    end
  end
end

def seed_fast_tick(message)
  puts message
  $stdout.flush
  sleep(SEED_TICK_SECONDS)
end

print_seed_banner
total_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
reset_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
deleted_records = reset_application_data!
puts "Reset: #{deleted_records} enregistrement(s) supprime(s) en #{format('%.1fs', Process.clock_gettime(Process::CLOCK_MONOTONIC) - reset_started_at)}"

if SEED_FAST_TEST
  ENV["SEED_POPULATION_COUNT"] ||= "8"

  puts "\n--- Mode SEED_FAST_TEST (~1 message / #{SEED_TICK_SECONDS}s) ---\n"

  %w[admin.rb membership_types.rb contribution_formulas.rb events.rb].each { |f| load_seed_file(f) }
  seed_fast_tick("[1/3] OK — Comptes système + catalogue + événements.")

  load_seed_file("populate.rb")
  seed_fast_tick("[2/3] OK — Population aléatoire (réduite).")

  seed_fast_tick("[3/3] OK — Seed terminée, récapitulatif ci-dessous.")
else
  SEED_STEPS.each_with_index do |(label, filename), index|
    step_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    render_step(index, SEED_STEPS.size, label, step_started_at)
    puts if SEED_VERBOSE
    load_seed_file(filename)
    render_progress(index + 1, SEED_STEPS.size, "#{label} (#{format('%.1fs', Process.clock_gettime(Process::CLOCK_MONOTONIC) - step_started_at)})", action: "ok")
  end
end

total_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - total_started_at

current_year = Date.current.year.to_s.last(2)

puts "\nPret pour dev/test:"
puts "  Catalogue: #{MembershipType.count} types, #{ContributionFormula.count} formules, #{Event.count} evenements"
puts "  Donnees: #{Person.count} personnes, #{User.count} comptes, #{Membership.count} adhesions, #{Payment.count} paiements"
puts "  Cotisations: #{Contribution.count}, Presences: #{Attendance.count}, Revendications: #{AccountClaim.count}"
puts "  Numeros: #{Person.where("member_number LIKE ?", "#{current_year}U%").count} basic, #{Person.where("member_number LIKE ?", "#{current_year}C%").count} cirque"
puts "  Duree totale: #{format('%.1fs', total_duration)}"

puts "\nComptes de test:"
SYSTEM_ACCOUNTS.each do |label, email, password|
  puts "  - #{label}: #{email} / #{password}"
end
puts "  - Comptes web population seed: *@seed.example.com / password123"
puts "\nOption: SEED_VERBOSE=true | SEED_FAST_TEST=true | SEED_LEAN=true (defaut moins de lignes)"
puts "        SEED_POPULATION_COUNT=N | SEED_RANDOM_SEED=chaîne (fixe le tirage)"

# ─── FAQ ──────────────────────────────────────────────────────────────────────
puts "\n=== FAQ ==="

Faq.destroy_all

contact_url = "/contact#contact-form"
become_member_url = "/adhesion#tarifs"
map_url = "/contact#map"

faq_data = [
  # AVANT VISITE — section "Avant de te déplacer" sur /adhesion
  { label: "avant_visite", position: 1, question: "Comment adhérer ?",
    answer: "Sur place, lors d'un créneau d'accueil : visite du lieu, fiche d'adhésion et explication de l'autogestion. Pas d'inscription en ligne — on fait ça ensemble au lieu pour que chacun·e parte avec les mêmes repères." },
  { label: "avant_visite", position: 2, question: "Paiement adhésion ou cotisation",
    answer: "Carte bancaire ou espèces à l'accueil, avec les bénévoles." },
  { label: "avant_visite", position: 3, question: "Je débute : les entraînements libres me concernent ?",
    answer: "Les créneaux libres cirque sont pour des pratiquant·es autonomes en sécurité. Pour apprendre les bases, une école partenaire ; pour une orientation, <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">écris-nous</a> en Question générale." },
  # ADHESION — onglet "Adhérer & pratiquer" sur /faq
  { label: "adhesion", position: 1, question: "Adhésion visiteur ou adhésion cirque : quelle différence ?",
    answer: "L'adhésion visiteur (don libre dès 1 €) donne accès aux temps ouverts sans pratique. L'adhésion cirque (10 €, tarif réduit 7 €) est nécessaire pour les entraînements libres — elle s'accompagne d'une cotisation à choisir selon ta pratique." },
  { label: "adhesion", position: 2, question: "Durée de l'adhésion",
    answer: "L'adhésion est annuelle, date à date à partir du jour de ta venue. La cotisation cirque (séance, carnet, trimestre ou annuelle) s'y ajoute selon tes besoins." },
  { label: "adhesion", position: 3, question: "Tarif réduit ou solidaire",
    answer: "Un tarif réduit à 7 € existe pour l'adhésion cirque. Parles-en directement aux bénévoles lors de ton accueil — on trouve toujours une solution." },
  # GENERAL — onglet "Lieu & horaires" sur /faq
  { label: "general", position: 1, question: "Adresse et accès",
    answer: "97 bis boulevard de Suisse, 31200 Toulouse. <a href=\"#{map_url}\" class=\"text-[#5836A5] underline\">Plan et bus (ligne 15)</a>." },
  { label: "general", position: 2, question: "Horaires",
    answer: "Les créneaux publics bougent selon la saison et les bénévoles. À jour sur l'accueil, la page Adhérer et la page Contact — jette un œil avant de venir." },
  { label: "general", position: 3, question: "Soutenir le lieu ou une question administrative",
    answer: "Adhérer, cotisation, don : <a href=\"#{become_member_url}\" class=\"text-[#5836A5] underline\">page Adhérer</a>. Pour un partenariat, un don hors cadre ou une demande administrative : <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">formulaire Contact</a> (Question générale ou Partenariat)." },
  # CONTACT — onglet "Écrire & proposer" sur /faq
  { label: "contact", position: 1, question: "Demander un temps d'accueil en création",
    answer: "Écris-nous avec le <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">formulaire Contact</a>, catégorie « Temps d'accueil en création » — on te répond sur les dispo et le cadre." },
  { label: "contact", position: 2, question: "Partenariat, atelier, événement ou projet avec le lieu",
    answer: "Le plus simple : passer lors d'un créneau d'ouverture avec ton idée. Tu peux aussi utiliser le <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">formulaire Contact</a> (Partenariat ou Question générale). Les bénévoles t'orientent." }
]

faq_data.each { |attrs| Faq.create!(attrs) }
puts "  #{Faq.count} entrées FAQ créées (avant_visite: #{Faq.by_label('avant_visite').count}, adhesion: #{Faq.by_label('adhesion').count}, general: #{Faq.by_label('general').count}, contact: #{Faq.by_label('contact').count})"
