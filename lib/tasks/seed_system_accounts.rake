# frozen_string_literal: true

namespace :circographe do
  desc "Charge db/seeds/admin.rb seulement (comptes super-admin, admin, volunteer). Dev/test : réapplique les mots de passe seed si déjà présents."
  task seed_system_accounts: :environment do
    load Rails.root.join("db/seeds/admin.rb")
  end
end
