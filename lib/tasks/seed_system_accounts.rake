# frozen_string_literal: true

namespace :circographe do
  desc "Charge db/seeds/admin.rb seulement (comptes super-admin, admin, volunteer). Dev/test : réapplique les mots de passe seed si déjà présents."
  task seed_system_accounts: :environment do
    load Rails.root.join("db/seeds/admin.rb")
  end

  desc "Récupération locale : db:prepare (development + test) puis db/seeds/admin.rb. Ne vide pas les données métier ; utile après migration ou DB vide."
  task fix_local_db: :environment do
    abort "circographe:fix_local_db — réservé à development ou test (pas #{Rails.env})" unless Rails.env.local?

    puts "[circographe:fix_local_db] db:prepare (development)..."
    system({ "RAILS_ENV" => "development" }, "bin/rails", "db:prepare", exception: true)

    puts "[circographe:fix_local_db] db:prepare (test)..."
    system({ "RAILS_ENV" => "test" }, "bin/rails", "db:prepare", exception: true)

    Rake::Task["circographe:seed_system_accounts"].reenable
    Rake::Task["circographe:seed_system_accounts"].invoke

    puts "[circographe:fix_local_db] Terminé. users=#{User.count} sessions=#{Session.count}"
    puts "[circographe:fix_local_db] Jeu de données complet : bin/rails db:seed"
  end
end
