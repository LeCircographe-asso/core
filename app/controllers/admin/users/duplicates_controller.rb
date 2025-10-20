module Admin
  module Users
    # Admin::Users::DuplicatesController handles duplicate detection
    # and management for users/persons. This controller is responsible for:
    # - Detecting duplicates
    # - Managing duplicate resolution
    # - Cleaning up duplicate records
    class DuplicatesController < BaseController
      before_action :set_breadcrumbs

      # GET /admin/users/duplicates
      def index
        @duplicate_report = DuplicateDetectionService.generate_report
        add_breadcrumb "Détection des doublons", nil
      end

      # POST /admin/users/duplicates/merge
      def merge
        primary_person_id = params[:primary_person_id]
        secondary_person_id = params[:secondary_person_id]
        
        primary_person = Person.find(primary_person_id)
        secondary_person = Person.find(secondary_person_id)
        
        result = MemberManagementService.merge_duplicate_persons(primary_person, secondary_person)
        
        if result[:success]
          redirect_to admin_users_duplicates_path, 
                      notice: "✅ Doublons fusionnés avec succès ! #{result[:transferred_count]} éléments transférés."
        else
          redirect_to admin_users_duplicates_path, 
                      alert: "❌ Erreur lors de la fusion: #{result[:error]}"
        end
      rescue => e
        redirect_to admin_users_duplicates_path, 
                    alert: "❌ Erreur lors de la fusion: #{e.message}"
      end

      # POST /admin/users/duplicates/cleanup
      def cleanup
        results = MemberManagementService.cleanup_duplicates
        
        success_count = results.count { |r| r[:result][:success] }
        error_count = results.count { |r| !r[:result][:success] }
        
        if error_count == 0
          redirect_to admin_users_duplicates_path, 
                      notice: "✅ Nettoyage automatique terminé ! #{success_count} doublons fusionnés."
        else
          redirect_to admin_users_duplicates_path, 
                      alert: "⚠️ Nettoyage partiel: #{success_count} succès, #{error_count} erreurs."
        end
      rescue => e
        redirect_to admin_users_duplicates_path, 
                    alert: "❌ Erreur lors du nettoyage automatique: #{e.message}"
      end

      # GET /admin/users/duplicates/identify
      def identify
        @duplicates = MemberManagementService.identify_duplicates
        add_breadcrumb "Identification des doublons", nil
      end

      # POST /admin/users/duplicates/assign_missing_numbers
      def assign_missing_numbers
        MemberManagementService.assign_missing_member_numbers
        
        redirect_to admin_users_duplicates_path, 
                    notice: "✅ Numéros d'adhérent assignés à toutes les personnes qui n'en avaient pas."
      rescue => e
        redirect_to admin_users_duplicates_path, 
                    alert: "❌ Erreur lors de l'assignation des numéros: #{e.message}"
      end

      private

      def set_breadcrumbs
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb "Gestion des doublons", nil
      end
    end
  end
end
