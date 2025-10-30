class Admin::Users::EditableMemberNumberComponent < ViewComponent::Base
  def initialize(person:, current_user:)
    @person = person
    @current_user = current_user
  end

  private

  attr_reader :person, :current_user

  def member_number
    person.member_number.present? ? person.member_number : ""
  end

  def can_edit?
    current_user&.can_edit_member_numbers?
  end

  def form_id
    "member_number_form_#{person.id}"
  end

  def input_id
    "member_number_input_#{person.id}"
  end
end
