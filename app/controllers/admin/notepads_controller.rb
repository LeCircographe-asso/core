# frozen_string_literal: true

module Admin
  class NotepadsController < BaseController
    include NotepadHelper

    before_action :set_breadcrumbs

    def edit
      @notepad = Rails.cache.fetch('notepad') || default_notepad
      add_breadcrumb 'Modifier le bloc-note', nil
    end

    def update
      updated_notepad = params[:notepad]
      Rails.cache.write('notepad', updated_notepad)
      redirect_to admin_dashboard_index_path, notice: 'Bloc-note mis à jour !'
    end

    private

    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end
  end
end
