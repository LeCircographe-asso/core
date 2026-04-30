# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home routing', type: :routing do
  it 'routes to #index' do
    expect(get: '/').to route_to('home#index')
  end
end
