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
      @membership_type = MembershipType.new(
        effective_from: Date.current,
        version: 1,
        created_by_user: Current.user
      )
      add_breadcrumb "Nouveau type d'adhésion", nil
    end

    def create
      creator = MembershipTypeManagement::MembershipTypeCreator.new(
        name: membership_type_params[:name],
        category: membership_type_params[:category],
        price_cents: membership_type_params[:price_cents],
        description: membership_type_params[:description],
        effective_from: membership_type_params[:effective_from] || Date.current,
        version: membership_type_params[:version] || 1,
        created_by_user_id: Current.user.id
      )

      result = creator.call

      if result.success?
        respond_to do |format|
          format.html { redirect_to admin_membership_types_path, notice: "Type d'adhésion créé avec succès !" }
          format.turbo_stream { redirect_to admin_membership_types_path, notice: "Type d'adhésion créé avec succès !" }
        end
      else
        @membership_type = MembershipType.new(membership_type_params)
        flash.now[:alert] = result.message
        render :new, status: :unprocessable_content
      end
    end

    def edit
      add_breadcrumb "Modifier: #{@membership_type.name}", nil
    end

    def update
      updater = MembershipTypeManagement::MembershipTypeUpdater.new(
        membership_type_id: @membership_type.id,
        name: membership_type_params[:name],
        category: membership_type_params[:category],
        price_cents: membership_type_params[:price_cents],
        description: membership_type_params[:description],
        effective_from: membership_type_params[:effective_from],
        updated_by_id: Current.user.id
      )

      result = updater.call

      if result.success?
        respond_to do |format|
          format.html { redirect_to admin_membership_types_path, notice: "Type d'adhésion mis à jour avec succès !" }
          format.turbo_stream { redirect_to admin_membership_types_path, notice: "Type d'adhésion mis à jour avec succès !" }
        end
      else
        flash.now[:alert] = result.message
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      deleter = MembershipTypeManagement::MembershipTypeDeleter.new(
        membership_type_id: @membership_type.id,
        deleted_by_id: Current.user.id
      )

      result = deleter.call

      if result.success?
        redirect_to admin_membership_types_path, notice: "Type d'adhésion supprimé avec succès !"
      else
        redirect_to admin_membership_types_path, alert: result.message
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
      params.require(:membership_type).permit(:name, :category, :price_cents, :description, :effective_from, :version, :created_by_user_id)
    end
  end
end
