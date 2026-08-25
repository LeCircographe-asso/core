# frozen_string_literal: true

class BugReportWidgetSetting < ApplicationRecord
  belongs_to :updated_by_user, class_name: "User", optional: true

  # Singleton : au plus une ligne pertinente à la fois, même pattern que ExceptionalClosure.
  def self.current
    first_or_create!
  end
end
