# frozen_string_literal: true

require "rails_helper"

RSpec.describe GalleryPhoto, type: :model do
  let(:image_path) { Rails.root.join("app/assets/images/lelieu1.webp") }

  it "is invalid without an image" do
    photo = GalleryPhoto.new
    expect(photo).not_to be_valid
    expect(photo.errors[:image]).to be_present
  end

  it "is valid with an attached image" do
    photo = GalleryPhoto.new
    photo.image.attach(io: File.open(image_path), filename: "lelieu1.webp")
    expect(photo).to be_valid
  end

  it "assigns the next position automatically" do
    first = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "a.webp" })
    second = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "b.webp" })

    expect(second.position).to eq(first.position + 1)
  end

  it "orders by position" do
    first = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "a.webp" })
    second = GalleryPhoto.create!(image: { io: File.open(image_path), filename: "b.webp" })
    second.update!(position: 0)

    expect(GalleryPhoto.ordered).to eq([ second, first ])
  end

  it "rejects a file larger than MAX_UPLOAD_SIZE" do
    photo = GalleryPhoto.new
    photo.image.attach(io: File.open(image_path), filename: "lelieu1.webp")
    allow(photo.image.blob).to receive(:byte_size).and_return(GalleryPhoto::MAX_UPLOAD_SIZE + 1)

    expect(photo).not_to be_valid
    expect(photo.errors[:image].join).to include("10 Mo")
  end

  it "rejects a non-image content type" do
    photo = GalleryPhoto.new
    photo.image.attach(io: File.open(image_path), filename: "notes.txt", content_type: "text/plain", identify: false)

    expect(photo).not_to be_valid
    expect(photo.errors[:image].join).to include("image")
  end
end
