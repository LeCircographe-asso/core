# frozen_string_literal: true

require "rails_helper"

RSpec.describe StagingAuth do
  let(:app) do
    lambda do |_env|
      [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ]
    end
  end

  subject(:middleware) { described_class.new(app) }

  def call_with(path, method: "GET", host: "staging.lecircographe.fr")
    env = Rack::MockRequest.env_for(
      path,
      method: method,
      "HTTP_HOST" => host
    )
    middleware.call(env)
  end

  before do
    ENV["STAGING_PASSWORD"] = "secret"
  end

  after do
    ENV.delete("STAGING_PASSWORD")
  end

  context "when request targets staging host" do
    it "returns 401 for / without credentials" do
      status, = call_with("/")
      expect(status).to eq(401)
    end

    it "allows /up without credentials" do
      status, = call_with("/up")
      expect(status).to eq(200)
    end

    it "allows GET /manifest.json without credentials" do
      status, = call_with("/manifest.json")
      expect(status).to eq(200)
    end

    it "allows HEAD /manifest without credentials" do
      status, = call_with("/manifest", method: "HEAD")
      expect(status).to eq(200)
    end

    it "allows GET /service-worker.js without credentials" do
      status, = call_with("/service-worker.js")
      expect(status).to eq(200)
    end

    it "allows /cable without HTTP Basic (WS handshake; auth via session in ApplicationCable)" do
      status, = call_with("/cable")
      expect(status).not_to eq(401)
    end
  end

  context "when host is not staging" do
    it "passes through without auth" do
      status, = call_with("/", host: "www.example.com")
      expect(status).to eq(200)
    end
  end
end
