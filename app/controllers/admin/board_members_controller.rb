# frozen_string_literal: true

module Admin
  class BoardMembersController < BaseController
    before_action :set_breadcrumbs
    before_action :require_admin_rights, only: %i[create update destroy reorder]
    before_action :set_board_member, only: %i[edit update destroy]

    def index
      @board_members = BoardMember.ordered
      add_breadcrumb I18n.t("breadcrumbs.admin.board_members.index"), nil
    end

    def new
      @board_member = BoardMember.new
    end

    def create
      @board_member = BoardMember.new(board_member_params)
      if @board_member.save
        redirect_to admin_board_members_path, notice: t(".created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @board_member.update(board_member_params)
        redirect_to admin_board_members_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reorder
      Array(params[:ids]).each_with_index do |id, index|
        BoardMember.find_by(id: id.to_i)&.update(display_order: index + 1)
      end
      head :ok
    end

    def destroy
      @board_member.destroy!
      redirect_to admin_board_members_path, notice: t(".destroyed"), status: :see_other
    end

    private

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
    end

    def set_board_member
      @board_member = BoardMember.find(params[:id])
    end

    def board_member_params
      params.expect(board_member: [ :name, :role, :bio, :avatar, :instagram_url, :linkedin_url, :behance_url ])
    end
  end
end
