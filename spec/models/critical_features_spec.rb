# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Critical Features', type: :model do
  describe 'User permissions' do
    it 'identifies admin users correctly' do
      admin_user = create(:user, system_role: :admin)
      regular_user = create(:user, system_role: :web_visitor)

      expect(admin_user.can_access_admin_zone?).to be_truthy
      expect(regular_user.can_access_admin_zone?).to be_falsey
    end

    it 'distinguishes exact role from cumulative admin rights' do
      super_admin = create(:user, system_role: :super_admin)
      admin_user = create(:user, system_role: :admin)

      # admin? est le prédicat strict natif de l'enum : un super_admin n'est pas "admin".
      expect(super_admin.admin?).to be_falsey
      expect(admin_user.admin?).to be_truthy

      # can_administer? regroupe super_admin et admin (droits cumulatifs).
      expect(super_admin.can_administer?).to be_truthy
      expect(admin_user.can_administer?).to be_truthy
    end
  end

  describe 'Event registration' do
    it 'can check if person is registered for event' do
      person = create(:person)
      event = create(:event)

      # Initially not registered
      expect(event.is_person_registered?(person)).to be_falsey
    end
  end

  describe 'Membership status' do
    it 'can determine active membership' do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = create(:membership, person: person, membership_type: membership_type, status: :active)

      expect(membership.active?).to be_truthy
    end
  end
end
