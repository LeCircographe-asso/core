module Admin
class MembershipController < BaseController
  before_action :set_person, only: [ :index, :create ]
  before_action :set_membership_types, only: [ :index ]

  def index
    # Adapter au nouveau modèle Person-Based
    @memberships = @person.memberships.includes(:membership_type).order(created_at: :desc)
    @membership_types = MembershipType.order(:category, :name)
  end

  def create
    # Créer une nouvelle adhésion avec le nouveau modèle
    @membership = @person.memberships.build(membership_params)

    if @membership.save
      redirect_to admin_membership_index_path(person_id: @person.id), notice: "Adhésion créée avec succès."
    else
      flash.now[:alert] = "Erreur lors de la création de l'adhésion."
      @memberships = @person.memberships.includes(:membership_type).order(created_at: :desc)
      render :index
    end
  end

  private

  def set_person
    if params[:person_id]
      @person = Person.find(params[:person_id])
    elsif params[:user_id]
      @user = User.find(params[:user_id])
      @person = @user.person
    end
  end

  def set_membership_types
    @membership_types = MembershipType.order(:category, :name)
  end

  def membership_params
    params.require(:membership).permit(:membership_type_id, :started_at, :ended_at, :status, :first_joined_at)
  end
end
end
