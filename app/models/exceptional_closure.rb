# frozen_string_literal: true

class ExceptionalClosure < ApplicationRecord
  belongs_to :updated_by_user, class_name: "User", optional: true

  # Singleton : au plus une ligne pertinente à la fois, pas d'historique de périodes.
  def self.current
    first_or_create!
  end

  def in_effect?
    active? && (ends_on.blank? || ends_on >= Date.current)
  end
end
