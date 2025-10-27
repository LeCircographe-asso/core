module Admin
  class MembershipTypesController < BaseController
    before_action :set_membership_type, only: [ :show, :edit, :update, :destroy ]
    before_action :set_breadcrumbs

    def index
      @membership_types = MembershipType.all.order(:category, :price_cents)
      add_breadcrumb "Types d'Adhésion", nil
    end

    def show
      @memberships = @membership_type.memberships.includes(:person).order(created_at: :desc).limit(10)
      add_breadcrumb "Type: #{@membership_type.name}", nil
    end

    def new
      @membership_type = MembershipType.new
      add_breadcrumb "Nouveau type d'adhésion", nil
    end

    def create
      @membership_type = MembershipType.new(membership_type_params)

      if @membership_type.save
        redirect_to admin_membership_type_path(@membership_type), notice: "Type d'adhésion créé avec succès !"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      add_breadcrumb "Modifier: #{@membership_type.name}", nil
    end

    def update
      if @membership_type.update(membership_type_params)
        redirect_to admin_membership_types_path, notice: "Type d'adhésion mis à jour avec succès !"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @membership_type.memberships.any?
        redirect_to admin_membership_types_path, alert: "Impossible de supprimer ce type d'adhésion car il est utilisé par des membres."
      else
        @membership_type.destroy
        redirect_to admin_membership_types_path, notice: "Type d'adhésion supprimé avec succès !"
      end
    end

    private

    def set_membership_type
      @membership_type = MembershipType.find(params[:id])
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_dashboard_index_path
      add_breadcrumb "Types d'Adhésion", admin_membership_types_path
    end

    def membership_type_params
      params.require(:membership_type).permit(:name, :category, :price_cents, :description)
    end
  end
end
