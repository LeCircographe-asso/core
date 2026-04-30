# frozen_string_literal: true

class MemberNumberHistoryComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  def render?
    person.member_number_history.exists?
  end

  private

  attr_reader :person

  def history_items
    person.member_number_history.order(:assigned_at).map do |history|
      status = history.current? ? "ACTUEL" : "PRÉCÉDENT"
      duration = history.duration / 1.day
      duration_text = history.current? ? "" : " (#{duration.round(1)}j)"

      content_tag :div, class: "history-item text-xs py-1 border-b border-gray-100 last:border-b-0" do
        content_tag(:span, "#{history.member_number} (#{status})", class: "font-mono font-semibold") +
          content_tag(:br) +
          content_tag(:span, history.notes, class: "text-gray-600") +
          content_tag(:br) +
          content_tag(:span, "Assigné le #{history.assigned_at.strftime('%d/%m/%Y %H:%M')}#{duration_text}", class: "text-gray-500")
      end
    end.join.html_safe
  end
end
