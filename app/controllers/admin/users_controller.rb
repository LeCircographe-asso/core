module Admin
  class UsersController < ApplicationController
    include Pagy::Backend
    layout 'admin'  # Pour garder ton layout admin
    before_action :require_admin_or_godmode  # Pour garder ta sécurité
    before_action :set_user, only: %i[ show edit update destroy ]

    # GET /admin/users or /admin/users.json
    def index
      scope = User.all

      # Recherche
      if params[:query].present?
        scope = scope.where("LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query OR LOWER(email_address) LIKE :query", 
          query: "%#{params[:query].downcase}%")
      end

      # Tri
      scope = case params[:sort]
        when "name"
          scope.order(last_name: sort_direction, first_name: sort_direction)
        when "created_at"
          scope.order(created_at: sort_direction)
        when "role"
          scope.order(role: sort_direction)
        else
          scope.order(created_at: :desc)
        end

      # Pagination avec un nombre fixe d'items par page
      @pagy, @users = pagy(scope, items: 20)

      # Pour les requêtes Turbo Frame
      if turbo_frame_request?
        render partial: "users_list", locals: { users: @users }
      end
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
    end

    # POST /admin/users or /admin/users.json
    def create
      @user = User.new(user_params)
      @user.password = generate_secure_password

      if @user.save
        membership_role = Role.find_or_create_by(name: "membership")

        @user.roles << membership_role

        payment = @user.payments.build(amount: 1, status: "pending", payment_method: "credit_card")
        payment.save!

        if Date.today.month < 9
          expiration_date = Date.new(Date.today.year, 9, 1)
        else
          expiration_date = Date.new(Date.today.year + 1, 9, 1)
        end

        subscription = SubscriptionType.find_by(name: "membership")
        if subscription.nil?
          subscription = SubscriptionType.create(name: "membership", price: 1, duration: "jusqu'au 01/09", description: "adhésion asso")
        end
        @user_membership = @user.user_memberships.create(
          subscription_type_id: subscription.id,
          status: "active",
          expiration_date: expiration_date
        )
      else

      end

      if @user.save
        membership_role = Role.find_or_create_by(name: "membership")

        @user.roles << membership_role

        payment = @user.payments.build(amount: 1, status: "pending", payment_method: "credit_card")
        payment.save!

        if Date.today.month < 9
          expiration_date = Date.new(Date.today.year, 9, 1)
        else
          expiration_date = Date.new(Date.today.year + 1, 9, 1)
        end

        subscription = SubscriptionType.find_by(name: "membership")
        if subscription.nil?
          subscription = SubscriptionType.create(name: "membership", price: 1, duration: "jusqu'au 01/09", description: "adhésion asso")
        end
        @user_membership = @user.user_memberships.create(
          subscription_type_id: subscription.id,
          status: "active",
          expiration_date: expiration_date
        )
      else

      end

      respond_to do |format|
        if @user.save
          format.html { redirect_to [ :admin, @user ], notice: "User was successfully created." }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to [ :admin, @user ], notice: "User was successfully updated." }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
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
      @user = User.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.fetch(:user, {})
      params.require(:user).permit(:email_address, :first_name, :last_name, :password, :payments, :roles)
    end

    def generate_secure_password
      SecureRandom.hex(10)
    end

    def require_admin_or_godmode
      unless Current.user&.role.in?(%w[admin godmode volunteer])
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : :asc
    end
    helper_method :sort_direction
  end
end
