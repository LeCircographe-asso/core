# Seeds - architecture Person-Based.
# Objectif: fournir un jeu de donnees court, centre use cases et tests.
# Voir docs/glossary.md pour le vocabulaire canonique.

SEED_VERBOSE = ActiveModel::Type::Boolean.new.cast(ENV["SEED_VERBOSE"])
SEED_FAST_TEST = ActiveModel::Type::Boolean.new.cast(ENV["SEED_FAST_TEST"])
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
  ["creation des parcours de test", "sample_people.rb"],
  ["creation des adhesions et paiements", "add_memberships_and_payments.rb"],
  ["palette etats UI (showcase)", "ui_showcase.rb"]
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

# Réduction proportionnelle en conservant les 11 lignes : une colonne sur +horizontal_step+ (2 ≈ moitié largeur).
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
  puts "\n--- Mode SEED_FAST_TEST (~1 message / #{SEED_TICK_SECONDS}s) ---\n"

  %w[admin.rb membership_types.rb contribution_formulas.rb events.rb].each { |f| load_seed_file(f) }
  seed_fast_tick("[1/4] OK — Comptes système (User/Person) + catalogue adhésions, formules cotisation, événements.")

  load_seed_file("sample_people.rb")
  seed_fast_tick("[2/4] OK — Personnes CRM & comptes web (création admin / bénévole / inscription web).")

  load_seed_file("add_memberships_and_payments.rb")
  load_seed_file("ui_showcase.rb")
  seed_fast_tick("[3/4] OK — Paiements & métier : adhésions, lignes de paiement, cotisations, dons, upgrades, scénarios doc + showcase UI.")

  seed_fast_tick("[4/4] OK — Seed terminée, récapitulatif ci-dessous.")
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
puts "  Numeros: #{Person.where("member_number LIKE ?", "#{current_year}U%").count} basic, #{Person.where("member_number LIKE ?", "#{current_year}C%").count} cirque"
puts "  Duree totale: #{format('%.1fs', total_duration)}"

puts "\nComptes de test:"
SYSTEM_ACCOUNTS.each do |label, email, password|
  puts "  - #{label}: #{email} / #{password}"
end
puts "  - Utilisateurs web seed: *@example.com / password123"
puts "  - Palette états UI: scenario.ui.*@example.com (voir db/seeds/ui_showcase.rb)"
puts "\nOption: SEED_VERBOSE=true | SEED_FAST_TEST=true | SEED_TICK_SECONDS=1 | SEED_BULK_USERS_COUNT=N (opt-in, rb: bulk_users.rb)"
