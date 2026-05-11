# frozen_string_literal: true

class HomeController < ApplicationController
  include OpeningHoursHelper

  allow_unauthenticated_access only: %i[index font_examples]

  def index
    @upcoming_events = Event.upcoming.by_date.limit(1)
    @opening_hours = current_opening_hours
  end

  def dashboard; end

  def font_examples
    # This is just a view-only action
  end
end
