# frozen_string_literal: true

module Admin
  class GalleryPhotosController < BaseController
    before_action :set_breadcrumbs
    before_action :require_admin_rights, only: %i[create destroy]

    def index
      @gallery_photos = GalleryPhoto.ordered
      @gallery_photo = GalleryPhoto.new
      add_breadcrumb I18n.t("breadcrumbs.admin.gallery_photos.gallery"), nil
    end

    def create
      @gallery_photo = GalleryPhoto.new(image: params.dig(:gallery_photo, :image), created_by_user: Current.user)

      if @gallery_photo.save
        redirect_to admin_gallery_photos_path, notice: t(".success")
      else
        redirect_to admin_gallery_photos_path, alert: @gallery_photo.errors.full_messages.to_sentence
      end
    end

    def destroy
      GalleryPhoto.find(params[:id]).destroy
      redirect_to admin_gallery_photos_path, notice: t(".success")
    end

    private

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
    end
  end
end
