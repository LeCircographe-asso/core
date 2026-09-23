# frozen_string_literal: true

require "io/console"

namespace :circographe do
  desc "Crée le premier super-admin (interactif ; mot de passe saisi sans écho, jamais lu depuis l'environnement). " \
       "Prod/staging : kamal app exec -i --reuse \"bin/rails circographe:create_super_admin\" -c config/deploy.<env>.yml"
  task create_super_admin: :environment do
    abort "circographe:create_super_admin — terminal interactif requis (kamal app exec -i)." unless $stdin.tty?

    ask = lambda do |label, env_key|
      ENV[env_key].presence || begin
        print "#{label} : "
        $stdin.gets.to_s.strip
      end
    end

    email = ask.call("Email", "SUPER_ADMIN_EMAIL")
    first_name = ask.call("Prénom", "SUPER_ADMIN_FIRST_NAME")
    last_name = ask.call("Nom", "SUPER_ADMIN_LAST_NAME")
    password = $stdin.getpass("Mot de passe (#{People::BootstrapSuperAdmin::MIN_PASSWORD_LENGTH} caractères min, non affiché) : ")
    puts
    password_confirmation = $stdin.getpass("Confirmer le mot de passe : ")
    puts

    result = People::BootstrapSuperAdmin.new(
      email: email, first_name: first_name, last_name: last_name,
      password: password, password_confirmation: password_confirmation
    ).call

    abort "Échec : #{result.errors.join(' / ')}" unless result.success?

    puts "Super-admin créé : #{result.user.email_address} (#{Rails.env})."
    puts "Connectez-vous, puis créez les autres comptes depuis l'interface d'administration."
  end
end
