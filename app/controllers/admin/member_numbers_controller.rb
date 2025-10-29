class Admin::MemberNumbersController < BaseController
  before_action :set_person, only: [:suggest, :change]

  # POST /admin/member_numbers/suggest
  def suggest
    membership_type = params[:membership_type] || 'BASIQUE'
    
    begin
      suggested_number = MemberManagementService.generate_member_number(membership_type)
      
      render json: {
        success: true,
        suggested_number: suggested_number,
        membership_type: membership_type
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/member_numbers/:person_id/change
  def change
    new_member_number = params[:member_number]
    new_membership_type = params[:new_membership_type]
    change_notes = params[:change_notes]

    begin
      # Valider le format du numéro
      unless MemberManagementService.valid_member_number_format?(new_member_number)
        raise "Format de numéro invalide. Utilisez le format YYTNNN (ex: 25C001)"
      end

      # Vérifier l'unicité
      if Person.exists?(member_number: new_member_number) || 
         MemberNumberHistory.exists?(member_number: new_member_number)
        raise "Ce numéro d'adhérent est déjà utilisé"
      end

      # Changer le numéro d'adhérent
      old_number = @person.member_number
      result = @person.change_member_number(new_membership_type, change_notes)
      
      if result
        # Mettre à jour le numéro actuel
        @person.update!(member_number: new_member_number)
        
        # Mettre à jour l'historique avec le bon numéro
        current_history = @person.current_member_number_history
        if current_history
          current_history.update!(
            member_number: new_member_number,
            notes: change_notes.present? ? change_notes : "Changement manuel de #{old_number} vers #{new_member_number}"
          )
        end

        render json: {
          success: true,
          message: "Numéro d'adhérent changé avec succès",
          old_number: old_number,
          new_number: new_member_number
        }
      else
        render json: {
          success: false,
          error: "Impossible de changer le numéro d'adhérent"
        }, status: :unprocessable_entity
      end
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_person
    @person = Person.find(params[:person_id]) if params[:person_id]
  end
end
