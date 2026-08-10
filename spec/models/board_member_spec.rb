# frozen_string_literal: true

require "rails_helper"

RSpec.describe BoardMember, type: :model do
  let(:image_path) { Rails.root.join("app/assets/images/lelieu1.webp") }

  it "is invalid without a name or a role" do
    member = BoardMember.new
    expect(member).not_to be_valid
    expect(member.errors[:name]).to be_present
    expect(member.errors[:role]).to be_present
  end

  it "is valid with name and role, avatar optional" do
    member = BoardMember.new(name: "Léa Martin", role: "Présidente")
    expect(member).to be_valid
  end

  it "assigns the next display_order automatically" do
    first = create(:board_member)
    second = create(:board_member)

    expect(second.display_order).to eq(first.display_order + 1)
  end

  it "orders by display_order then created_at" do
    second = create(:board_member, display_order: 2)
    first = create(:board_member, display_order: 1)

    expect(BoardMember.ordered).to eq([ first, second ])
  end

  it "rejects an oversized avatar" do
    member = BoardMember.new(name: "Léa Martin", role: "Présidente")
    member.avatar.attach(io: File.open(image_path), filename: "lelieu1.webp")
    allow(member.avatar.blob).to receive(:byte_size).and_return(BoardMember::MAX_UPLOAD_SIZE + 1)

    expect(member).not_to be_valid
    expect(member.errors[:avatar]).to be_present
  end

  it "rejects a non-image avatar content type" do
    member = BoardMember.new(name: "Léa Martin", role: "Présidente")
    member.avatar.attach(io: File.open(image_path), filename: "notes.txt", content_type: "text/plain", identify: false)

    expect(member).not_to be_valid
    expect(member.errors[:avatar]).to be_present
  end

  describe "#socials" do
    it "only includes the platforms with a URL set" do
      member = build(:board_member, instagram_url: "https://instagram.com/lea", linkedin_url: nil, behance_url: nil)

      expect(member.socials).to eq(instagram: "https://instagram.com/lea")
    end

    it "is empty when no social URL is set" do
      member = build(:board_member)

      expect(member.socials).to eq({})
    end
  end
end
