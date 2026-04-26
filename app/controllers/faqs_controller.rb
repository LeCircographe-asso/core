class FaqsController < ApplicationController
  def index
    data = FaqRepository.load

    @hero = data[:hero]
    @entries = data[:entries]
    @cta_label = data[:cta_label]
  end
end
