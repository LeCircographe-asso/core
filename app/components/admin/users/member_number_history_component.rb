class Admin::Users::MemberNumberHistoryComponent < ViewComponent::Base
  def initialize(person:, current_user:)
    @person = person
    @current_user = current_user
  end

  private

  attr_reader :person, :current_user

  def can_edit?
    current_user&.can_edit_member_numbers?
  end

  def member_number_history
    person.member_number_history.order(:assigned_at)
  end

  def current_member_number
    person.member_number
  end

  def has_history?
    member_number_history.count > 1
  end

  def format_date(date)
    date.strftime('%d/%m/%Y à %H:%M')
  end

  def duration_display(history_item)
    if history_item.current?
      'Actuel'
    elsif history_item.replaced_at.present?
      duration = history_item.duration
      days = (duration / 1.day).round
      if days < 1
        "Moins d'un jour"
      elsif days == 1
        '1 jour'
      else
        "#{days} jours"
      end
    else
      'En cours'
    end
  end

  def status_class(history_item)
    if history_item.current?
      'bg-green-100 text-green-800'
    else
      'bg-gray-100 text-gray-600'
    end
  end
end
