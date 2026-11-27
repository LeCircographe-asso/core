# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::Progress do
  let(:user) { create(:user, :admin) }
  let(:token) { SecureRandom.uuid }

  before { Rails.cache.clear }

  it "stores progress every few rows and on the last row" do
    progress = described_class.new(user:, token:)

    progress.update(3, 25)
    expect(progress.read).to eq(processed: 0, total: nil)

    progress.update(10, 25)
    expect(progress.read).to eq(processed: 10, total: 25)

    progress.update(25, 25)
    expect(progress.read).to eq(processed: 25, total: 25)
  end

  it "is scoped to the user" do
    described_class.new(user:, token:).update(10, 10)

    expect(described_class.new(user: create(:user, :admin), token:).read).to eq(processed: 0, total: nil)
  end

  it "ignores malformed tokens" do
    progress = described_class.new(user:, token: "../../other-key")
    progress.update(10, 10)

    expect(progress.read).to eq(processed: 0, total: nil)
  end
end
