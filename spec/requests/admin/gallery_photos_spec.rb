# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::GalleryPhotos", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:image_path) { Rails.root.join("app/assets/images/lelieu1.webp") }

  before { login_as(admin) }

  describe "GET /admin/gallery_photos" do
    it "returns http success" do
      get admin_gallery_photos_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/gallery_photos" do
    it "attaches the uploaded image and creates a GalleryPhoto" do
      expect do
        post admin_gallery_photos_path, params: {
          gallery_photo: { image: Rack::Test::UploadedFile.new(image_path, "image/webp") }
        }
      end.to change(GalleryPhoto, :count).by(1)

      expect(response).to redirect_to(admin_gallery_photos_path)
      expect(GalleryPhoto.last.image).to be_attached
    end

    it "is forbidden for a volunteer" do
      login_as(create(:user, :volunteer))

      expect do
        post admin_gallery_photos_path, params: {
          gallery_photo: { image: Rack::Test::UploadedFile.new(image_path, "image/webp") }
        }
      end.not_to change(GalleryPhoto, :count)
    end
  end

  describe "PATCH /admin/gallery_photos/reorder" do
    it "updates position from the given ids order" do
      first = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "lelieu1.webp" })
      second = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "lelieu1.webp" })

      patch reorder_admin_gallery_photos_path, params: { ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:ok)
      expect(second.reload.position).to eq(1)
      expect(first.reload.position).to eq(2)
    end

    it "is forbidden for a volunteer" do
      login_as(create(:user, :volunteer))
      photo = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "lelieu1.webp" }, position: 1)

      patch reorder_admin_gallery_photos_path, params: { ids: [ photo.id ] }

      expect(photo.reload.position).to eq(1)
    end
  end

  describe "DELETE /admin/gallery_photos/:id" do
    it "destroys the photo" do
      photo = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "lelieu1.webp" })

      expect do
        delete admin_gallery_photo_path(photo)
      end.to change(GalleryPhoto, :count).by(-1)

      expect(response).to redirect_to(admin_gallery_photos_path)
    end
  end
end
