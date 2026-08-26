# frozen_string_literal: true

module Admin
  class FaqsController < BaseController
    before_action :set_faq, only: %i[edit update destroy]

    def index
      @faqs = Faq.ordered.group_by(&:label)
      @labels = Faq::LABELS
    end

    def new
      @faq = Faq.new(label: params[:label] || "general")
    end

    def create
      @faq = Faq.new(faq_params)
      if @faq.save
        redirect_to admin_faqs_path, notice: t(".created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @faq.update(faq_params)
        redirect_to admin_faqs_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def reorder
      Array(params[:ids]).each_with_index do |id, index|
        Faq.find_by(id: id.to_i)&.update(position: index + 1)
      end
      head :ok
    end

    def destroy
      @faq.destroy!
      redirect_to admin_faqs_path, notice: t(".destroyed"), status: :see_other
    end

    private

    def set_faq
      @faq = Faq.find(params[:id])
    end

    def faq_params
      params.expect(faq: [ :question, :answer, :label, :position ])
    end
  end
end
