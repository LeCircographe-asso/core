# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserManagement::UserDeleter do
  let(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }

  def call(person, deleted_by)
    described_class.new(person_id: person.id, deleted_by_id: deleted_by.id, reason: "spec").call
  end

  it "archives a person without financial data" do
    person = create(:person)

    result = call(person, admin)

    expect(result).to be_success
    expect(person.reload).to be_archived
  end

  it "refuses an admin deleting a person with payments" do
    person = create(:person)
    create(:payment, :success, person: person)

    result = call(person, admin)

    expect(result).not_to be_success
    expect(person.reload).not_to be_archived
  end

  it "refuses an admin deleting an account of equal rank" do
    person = create(:person)
    create(:user, :admin, person: person, email_address: person.email)

    result = call(person, admin)

    expect(result).not_to be_success
    expect(person.reload).not_to be_archived
  end

  # The service lets a super_admin skip the financial-data check, but
  # Person#archive! still refuses and returns false. The service must not
  # report success when nothing was archived.
  it "does not report success when the person was not archived" do
    person = create(:person)
    create(:payment, :success, person: person)

    result = call(person, super_admin)

    expect(person.reload).not_to be_archived
    expect(result).not_to be_success
  end
end
