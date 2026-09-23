# frozen_string_literal: true

module Seeds
  # Décide quel profil de seeds `db/seeds.rb` doit exécuter.
  #
  # - demo (development/test par défaut) : comptes système, catalogue, événements, population
  #   aléatoire — et remise à zéro complète de la base au préalable.
  # - contenu seul (staging/production par défaut) : FAQ, conseil d'administration, partenaires,
  #   uniquement si leur table est vide. Aucun compte, aucun catalogue (types d'adhésion et
  #   formules de cotisation sont saisis via l'admin), aucune suppression.
  #
  # `db:prepare` lance `db:seed` au premier boot d'une base fraîche : ce profil garantit qu'une
  # base de production ne reçoit jamais de compte `123456` ni de données de démonstration.
  class Profile
    class DemoSeedInProductionError < StandardError; end

    # fichier de db/seeds/ => modèle dont la table doit être vide pour que le seed s'applique
    CONTENT_SEEDS = {
      "faq.rb" => "Faq",
      "board_members.rb" => "BoardMember",
      "partners.rb" => "Partner"
    }.freeze

    def self.demo?(env: Rails.env, flag: ENV.fetch("SEED_DEMO", nil))
      demo = flag.present? ? ActiveModel::Type::Boolean.new.cast(flag) : (env.development? || env.test?)

      if demo && env.production?
        raise DemoSeedInProductionError,
              "SEED_DEMO refusé en production : les seeds de démonstration effaceraient les données réelles."
      end

      demo
    end
  end
end
