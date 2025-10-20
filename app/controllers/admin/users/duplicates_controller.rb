module Admin
  module Users
    class DuplicatesController < Admin::BaseController
      before_action :ensure_admin_access

      def index
        @duplicate_report = find_duplicate_people
        @breadcrumbs = ["Utilisateurs", "Détection des doublons"]
      end

      def merge
        primary_person = Person.find_by(id: params[:primary_person_id])
        secondary_person = Person.find_by(id: params[:secondary_person_id])

        if primary_person && secondary_person
          merge_people(primary_person, secondary_person)
          redirect_to duplicates_admin_users_path, notice: "Doublons fusionnés avec succès"
        else
          redirect_to duplicates_admin_users_path, alert: "Personnes non trouvées"
        end
      end

      private

      def find_duplicate_people
        # Logique simple de détection de doublons basée sur le nom
        Person.joins(:user)
              .group(:first_name, :last_name)
              .having("COUNT(*) > 1")
              .pluck(:first_name, :last_name)
      end

      def merge_people(primary, secondary)
        # Transférer les adhésions, paiements, etc. vers la personne principale
        secondary.memberships.update_all(person_id: primary.id)
        secondary.payments.update_all(person_id: primary.id)
        secondary.book_of_entries.update_all(person_id: primary.id)
        secondary.attendances.update_all(person_id: primary.id)
        
        # Supprimer la personne secondaire
        secondary.destroy
      end

      def ensure_admin_access
        unless current_user&.has_admin?
          redirect_to root_path, alert: "Vous n'avez pas accès à cette page"
        end
      end
    end
  end
end