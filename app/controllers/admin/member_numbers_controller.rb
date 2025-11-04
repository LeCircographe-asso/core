class Admin::MemberNumbersController < Admin::BaseController
  before_action :set_person, only: [:suggest, :change]

  # POST /admin/member_numbers/suggest
  def suggest
    suggester = MemberNumberManagement::MemberNumberSuggester.new(
      membership_type: params[:membership_type] || 'BASIQUE'
    )

    result = suggester.call

    if result.success?
      render json: {
        success: true,
        suggested_number: result.suggested_number,
        membership_type: result.membership_type
      }
    else
      render json: {
        success: false,
        error: result.message
      }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/member_numbers/:person_id/change
  def change
    changer = MemberNumberManagement::MemberNumberChanger.new(
      person_id: @person.id,
      new_member_number: params[:member_number],
      new_membership_type: params[:new_membership_type],
      change_notes: params[:change_notes],
      changed_by_id: Current.user.id
    )

    result = changer.call

    if result.success?
      render json: {
        success: true,
        message: result.message,
        old_number: result.old_number,
        new_number: result.new_number
      }
    else
      render json: {
        success: false,
        error: result.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_person
    @person = Person.find(params[:person_id]) if params[:person_id]
  end
end
