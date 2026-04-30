# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaintenanceModeMiddleware do
  let(:app) do
    lambda do |_env|
      [200, { 'Content-Type' => 'text/plain' }, ['OK']]
    end
  end

  subject(:middleware) { described_class.new(app) }

  let(:flag_path) { Rails.root.join('tmp/maintenance.flag') }

  around do |example|
    original_env = ENV.fetch('MAINTENANCE_MODE', nil)
    FileUtils.rm_f(flag_path)

    example.run
  ensure
    if original_env.nil?
      ENV.delete('MAINTENANCE_MODE')
    else
      ENV['MAINTENANCE_MODE'] = original_env
    end
    FileUtils.rm_f(flag_path)
  end

  def call_with(path, method: 'GET')
    env = Rack::MockRequest.env_for(path, method: method)
    middleware.call(env)
  end

  context 'when MAINTENANCE_MODE env is true' do
    before { ENV['MAINTENANCE_MODE'] = 'true' }

    it 'returns 503 for standard requests' do
      status, _headers, _body = call_with('/')
      expect(status).to eq(503)
    end

    it 'allows manifest requests' do
      status, _headers, _body = call_with('/manifest')
      expect(status).to eq(200)
    end

    it 'allows service worker requests' do
      status, _headers, _body = call_with('/service-worker.js')
      expect(status).to eq(200)
    end

    it 'allows HEAD requests for manifest' do
      status, _headers, _body = call_with('/manifest.json', method: 'HEAD')
      expect(status).to eq(200)
    end
  end

  context 'when the maintenance flag file exists' do
    before do
      FileUtils.mkdir_p(flag_path.dirname)
      File.write(flag_path, "true\n")
    end

    it 'returns 503 for standard requests' do
      status, _headers, _body = call_with('/')
      expect(status).to eq(503)
    end

    it 'treats empty file content as true' do
      File.write(flag_path, '')
      status, _headers, _body = call_with('/')
      expect(status).to eq(503)
    end
  end

  context 'when maintenance is disabled' do
    before { ENV['MAINTENANCE_MODE'] = 'false' }

    it 'passes through to the app' do
      status, _headers, _body = call_with('/')
      expect(status).to eq(200)
    end
  end
end
