module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[ show edit update destroy ]

    # GET /admin/users or /admin/users.json
    def index
      @users = User.all
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show
    end

    # GET /admin/users/new
    def new
      @user = User.new
    end

    # GET /admin/users/1/edit
    def edit
      @can_promote = User.system_roles.key(@user.system_role_before_type_cast - 1) if can_promote?(@user)
      @can_demote = User.system_roles.key(@user.system_role_before_type_cast + 1) if can_demote?(@user)



     
      
    end

    # POST /admin/users or /admin/users.json
    def create
      @user = User.new(user_params)
      @user.password = generate_secure_password

      respond_to do |format|
        if @user.save
          if subscribe_to_newsletter == true
            UserMailer.newsletter_subscription(@user).deliver_now
          end
          @user.generate_password_reset_token!
          UserMailer.welcome_by_admin(@user).deliver_now
          format.html { redirect_to [ :admin, @user ], notice: "User was successfully created. A mail has been sent !" }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end


    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      p "#"*111
      
      if params.require(:user)[:promote_role] == "1" && can_promote?(@user)
        @user.update(system_role: User.system_roles.key(@user.system_role_before_type_cast - 1))
        redirect_to [ :admin, @user ], notice: "User was successfully updated."
      end
      
      if params.require(:user)[:reduce_role] == "1" && can_demote?(@user)
        @user.update(system_role: User.system_roles.key(@user.system_role_before_type_cast + 1))
        redirect_to [ :admin, @user ], notice: "User was successfully updated."
      end
      
      p "#"*111

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
      params.fetch(:user, {})
      params.require(:user).permit(:email_address, :first_name, :last_name, :password, :payments, :system_role, :subscribe_to_newsletter)
    end

    def generate_secure_password
      SecureRandom.hex(10)
    end

    def can_promote?(other_user)
      current_user.system_role_before_type_cast < other_user.system_role_before_type_cast - 1
    end
    
    def can_demote?(other_user)
      current_user.system_role_before_type_cast < other_user.system_role_before_type_cast && other_user.system_role_before_type_cast != 3
    end

  end
end



