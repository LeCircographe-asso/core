module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[ show edit update destroy ]
    before_action :set_breadcrumbs

    # GET /admin/users or /admin/users.json
    def index
      @users = User.all
      
      # Statistiques pour le dashboard
      @total_users = User.count
      @new_users_yesterday = User.where("created_at >= ? AND created_at <= ?", 1.day.ago.beginning_of_day, 1.day.ago.end_of_day).count
      @basic_memberships = UserMembership.joins(:membership).where(memberships: { type_name: 'Basic' }, status: 'active').count
      @circus_memberships = UserMembership.joins(:membership).where(memberships: { type_name: 'Circus' }, status: 'active').count
      @active_memberships = UserMembership.where(status: 'active').count
      @users_this_month = User.where(created_at: Time.current.beginning_of_month..Time.current).count
      
      add_breadcrumb "Liste d'adhérents", nil
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show
      @array_right = current_user.has_higher_permissions?(@user) ? current_user.inferior_rights : [@user.system_role]

      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb @user.full_name.present? ? @user.full_name : "Utilisateur ##{@user.id}", nil

      respond_to do |format|
        format.html
        format.json { render json: @user }
      end
    end

    # GET /admin/users/new
    def new
      @user = User.new
      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb "Nouvel adhérent", nil
    end

    # GET /admin/users/1/edit
    def edit
      Rails.logger.debug "Edit action called for user ID: #{params[:id]}"
      Rails.logger.debug "@user: #{@user.inspect}"
      Rails.logger.debug "current_user: #{current_user.inspect}"
      
      if @user.nil?
        Rails.logger.debug "User is nil, redirecting to users list"
        redirect_to admin_users_path, alert: "Utilisateur non trouvé."
        return
      end
      
      begin
        @array_right = current_user.has_higher_permissions?(@user) ? current_user.inferior_rights : [@user.system_role]
        Rails.logger.debug "@array_right: #{@array_right.inspect}"
        @default_role = @user.system_role
        Rails.logger.debug "@default_role: #{@default_role.inspect}"
      rescue => e
        Rails.logger.error "Error in edit action: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to admin_users_path, alert: "Une erreur est survenue lors de l'édition de l'utilisateur."
        return
      end

      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb @user.full_name.present? ? @user.full_name : "Utilisateur ##{@user.id}", admin_user_path(@user)
      add_breadcrumb "Modifier", nil
    end

    # POST /admin/users or /admin/users.json
    def create
      @user = User.new(user_params)
      @user.created_by_admin = true
      @user.password = generate_secure_password
      @default_membership = Membership.find_by(type_name: :No_Member)

      begin
        User.transaction do
          if @user.save
            @order = @user.orders.new
            @user_membership = UserMembership.create!(user: @user, membership_id: @default_membership.id)

            if @order.save
              redirect_to admin_user_order_path(id: @order, user_id: @user),
              notice: "Utilisateur créé avec succès. Un mail a été envoyé !"
              Rails.logger.info "Redirection vers : #{admin_user_order_path(id: @order.id, user_id: @user.id)}"
            else
              Rails.logger.info "User, Order et UserMembership créés avec succès"
            end
          end
        end
      rescue => e
        Rails.logger.error "Erreur lors de la création de l'utilisateur : #{e.message}"
        redirect_to new_admin_user_path, alert: "Erreur lors de la création de l'utilisateur."
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour avec succès." }
          format.json { render json: @user }
          format.turbo_stream { 
            flash.now[:notice] = "Utilisateur mis à jour avec succès."
            render turbo_stream: [
              turbo_stream.replace(@user),
              turbo_stream.replace("flash", partial: "shared/flash")
            ]
          }
        else
          format.html { render :show, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
          format.turbo_stream { 
            render turbo_stream: turbo_stream.replace(
              "error_explanation",
              partial: "shared/error_messages",
              locals: { resource: @user }
            )
          }
        end
      end
    end

    # DELETE /admin/users/1 or /admin/users/1.json
    def destroy
      @user.destroy!

      respond_to do |format|
        format.html { redirect_to admin_users_path, status: :see_other, notice: "Utilisateur supprimé avec succès." }
        format.json { head :no_content }
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find_by(id: params[:id])
    end

    def set_breadcrumbs
      add_breadcrumb "Dashboard", admin_dashboard_index_path
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(
        :email_address,
        :first_name,
        :last_name,
        :birthdate,
        :address,
        :zip_code,
        :town,
        :country,
        :phone_number,
        :occupation,
        :specialty,
        :image_rights,
        :get_involved,
        :system_role,
        :newsletter_subscribed,
        :dyslexic_font
      )
    end

    def generate_secure_password
      SecureRandom.hex(10)
    end
  end
end
