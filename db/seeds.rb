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

SEED_STEPS_BASE = [
  ["creation des comptes systeme", "admin.rb"],
  ["catalogue des types d'adhesion", "membership_types.rb"],
  ["catalogue des formules de cotisation", "contribution_formulas.rb"],
  ["creation des evenements", "events.rb"],
  ["FAQ", "faq.rb"],
  ["conseil d'administration", "board_members.rb"],
  ["partenaires", "partners.rb"]
].freeze

SEED_STEPS_FULL = (SEED_STEPS_BASE + [
  ["population aleatoire (users, adhesions, cotisations)", "populate.rb"]
]).freeze

SEED_STEPS = SEED_LEAN ? SEED_STEPS_BASE : SEED_STEPS_FULL

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

  %w[admin.rb membership_types.rb contribution_formulas.rb events.rb faq.rb board_members.rb partners.rb].each { |f| load_seed_file(f) }
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

