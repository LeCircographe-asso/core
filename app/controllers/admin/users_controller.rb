module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[ show edit update destroy ]

    # GET /admin/users or /admin/users.json
    def index
      @users = User.all
      @total_user_memberships = UserMembership.where(status: "active").count
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show
      @user = User.find_by(id: params[:id])
      @product_order = Product.find_by(params[:id])
      @product = Product.find_by(params[:id])
    end

    # GET /admin/users/new
    def new
      @user = User.new
    end

    # GET /admin/users/1/edit
    def edit
      @array_right = current_user.has_higher_permissions?(User.find(params[:id])) ? current_user.inferior_rights : [User.find(params[:id]).system_role]
      @default_role = User.find(params[:id]).system_role
    end

    # POST /admin/users or /admin/users.json
    def create
      @user = User.new(user_params)
      @user.password = generate_secure_password
      @default_membership = Membership.find_by(type_name: :No_Member)

      begin
        User.transaction do
          if @user.save
            @order = @user.orders.create!
            @user_membership = UserMembership.create!(user: @user, membership_id: @default_membership.id)
        #   if newsletter_subscribed == true
        #     UserMailer.welcome_by_admin(@user).deliver_now
        #   end
        Rails.logger.info "Redirection vers : #{admin_user_order_path(id: @order.id, user_id: @user.id)}"
          end
        end
        # Si la transaction réussit
        respond_to do |format|
          Rails.logger.info "User, Order et UserMembership créés avec succès"
          @user.generate_password_reset_token!

          reset_password_url = @user.reset_password_url
          UserMailer.welcome_by_admin(@user, reset_password_url).deliver_now

          format.html {
            redirect_to admin_user_order_path(id: @order.id, user_id: @user.id), 
            notice: "User was successfully created. A mail has been sent!" 
          }
        end

      rescue ActiveRecord::RecordInvalid => e
        # Gestion centralisée des erreurs
        Rails.logger.error "Erreur de création : #{e.record.errors.full_messages.join(', ')}"

        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: e.record.errors, status: :unprocessable_entity }
        end
      end
    end



    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      if current_user.inferior_rights.include?(params[:user][:system_role])
        if @user.update(user_params)
          redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour avec succès."
        else
          redirect_to admin_user_path(@user), alert: "Échec de la mise à jour de l'utilisateur."
        end
      else
        redirect_to admin_user_path(@user), alert: "Vous n'avez pas les droits pour effectuer cette modification."
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
      @user = User.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:email_address, :first_name, :last_name, :password, :payments, :system_role, :newsletter_subscribed, :reset_password_url)
    end

    def generate_secure_password
      SecureRandom.hex(10)
    end
  end
end
