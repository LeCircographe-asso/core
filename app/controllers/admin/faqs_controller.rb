# frozen_string_literal: true

module Admin
  class FaqsController < BaseController
    def edit
      data = FaqRepository.load
      @hero      = data[:hero]
      @cta_label = data[:cta_label]
      @entries   = data[:entries]
    end

    def update
      data = JSON.parse(faq_params.to_json)
      File.write(FaqRepository::CONFIG_PATH, YAML.dump(data))
      Rails.cache.delete(FaqRepository::CACHE_KEY)
      redirect_to edit_admin_faq_path, notice: t(".updated")
    end

    private

    def faq_params
      params.require(:faq).permit(:hero, :cta_label, entries: %i[question answer])
    end
  end
end
