# frozen_string_literal: true

module Admin
  class FaqConfigController < BaseController
    def edit
      @faq_data = FaqRepository.load
    end

    def update
      entries = Array.wrap(params.dig(:faq, :entries)).map do |e|
        { question: e[:question].to_s, answer: e[:answer].to_s }
      end

      FaqRepository.save(
        hero:      params.dig(:faq, :hero).to_s,
        cta_label: params.dig(:faq, :cta_label).to_s,
        entries:   entries
      )

      redirect_to edit_admin_faq_path, notice: t(".updated")
    end
  end
end
