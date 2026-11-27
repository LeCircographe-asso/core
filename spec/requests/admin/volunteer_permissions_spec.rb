# frozen_string_literal: true

require "rails_helper"

# Server-side guards for the volunteer role.
#
# Reference: docs/domain/role_permissions.md, plus the product decisions taken
# while writing this spec (2026-11-26):
#   - payments: a volunteer may RECORD a payment, but not update, cancel,
#     restore or process one;
#   - donations: a volunteer may record a donation.
#
# Each "forbidden" example asserts on persisted state, not on a specific
# redirect: whatever the guard looks like, the write must not happen.
RSpec.describe "Volunteer permissions in the admin zone", type: :request do
  let(:volunteer) { create(:user, :volunteer) }

  before { login_as(volunteer) }

  describe "members (Admin::MembersController)" do
    it "cannot create a member" do
      expect do
        post admin_members_path, params: {
          member: { person: { first_name: "Jane", last_name: "Doe", email: "jane.doe@example.test" } }
        }
      end.not_to change(Person, :count)
    end

    it "cannot update a member's personal data" do
      person = create(:person, first_name: "Original")

      patch admin_member_path(person), params: { person: { first_name: "Changed" } }

      expect(person.reload.first_name).to eq("Original")
    end

    it "cannot update a member's web account" do
      person = create(:person, :with_user)
      original_email = person.user.email_address

      patch admin_member_path(person), params: { member: { email_address: "changed@example.test" } }

      expect(person.user.reload.email_address).to eq(original_email)
    end

    it "cannot archive a member" do
      person = create(:person)

      delete admin_member_path(person)

      expect(person.reload).not_to be_archived
    end

    it "cannot create a web account for a member" do
      person = create(:person, email: "no-account@example.test")

      expect do
        post create_web_account_admin_member_path(person)
      end.not_to change(User, :count)
    end
  end

  describe "payments (Admin::PaymentsController)" do
    let(:person) { create(:person) }

    it "can record a payment" do
      expect do
        post admin_payments_path, params: {
          payment: { person_id: person.id, total_cents: "10", payment_method: "cash" }
        }
      end.to change(Payment, :count).by(1)
    end

    it "cannot update a payment" do
      payment = create(:payment, :success, person: person, total_cents: 1500)

      patch admin_payment_path(payment), params: { payment: { total_cents: "99" } }

      expect(payment.reload.total_cents).to eq(1500)
    end

    it "cannot cancel a payment" do
      payment = create(:payment, :success, person: person)

      delete admin_payment_path(payment)

      expect(payment.reload).not_to be_cancel
    end

    it "cannot restore a cancelled payment" do
      payment = create(:payment, :cancel, person: person)

      post restore_admin_payment_path(payment)

      expect(payment.reload).to be_cancel
    end
  end

  describe "member payments (Admin::Members::PaymentsController)" do
    let(:person) { create(:person) }

    it "can record a payment" do
      expect do
        post admin_member_payments_path(person), params: {
          payment: { total_cents: "1000", payment_method: "cash" }
        }
      end.to change(Payment, :count).by(1)
    end

    it "cannot update a payment" do
      payment = create(:payment, :success, person: person, total_cents: 1500)

      patch admin_member_payment_path(person, payment), params: { payment: { total_cents: "99" } }

      expect(payment.reload.total_cents).to eq(1500)
    end

    it "cannot cancel a payment" do
      payment = create(:payment, :success, person: person)

      delete admin_member_payment_path(person, payment)

      expect(payment.reload).not_to be_cancel
    end

    it "cannot process a pending payment" do
      payment = create(:payment, :pending, person: person)

      post process_payment_admin_member_payment_path(person, payment)

      expect(payment.reload).to be_pending
    end
  end

  describe "donations (Admin::DonationsController)" do
    it "can record a donation" do
      person = create(:person)

      expect do
        post admin_donations_path, params: { person_id: person.id, payment: { payment_amount: "5" } }
      end.to change(Payment, :count).by(1)
    end
  end

  describe "membership sales (Admin::MembershipsController)" do
    let(:person) { create(:person) }
    let(:membership_type) { create(:membership_type) }

    it "cannot sell a membership" do
      expect do
        post admin_memberships_path, params: {
          membership: { person_id: person.id, membership_type_id: membership_type.id, payment_method: "cash" }
        }
      end.not_to change(Membership, :count)
    end

    it "cannot update a membership" do
      membership = create(:membership, person: person, membership_type: membership_type, status: :active)
      other_type = create(:membership_type)

      patch admin_membership_path(person), params: { membership: { membership_type_id: other_type.id } }

      expect(membership.reload.membership_type).to eq(membership_type)
    end

    it "cannot deactivate a membership" do
      membership = create(:membership, person: person, membership_type: membership_type, status: :active)

      delete admin_membership_path(person)

      expect(membership.reload).to be_active
    end
  end

  describe "contribution sales (Admin::ContributionsController)" do
    it "cannot sell a contribution" do
      person = create(:person, :with_circus_membership)
      formula = create(:contribution_formula, :pack10, membership_type: person.current_membership.membership_type)

      expect do
        post admin_contributions_path, params: {
          person_id: person.id,
          contribution: { contribution_formula_id: formula.id, payment_method: "cash" }
        }
      end.not_to change(Contribution, :count)
    end
  end

  describe "blogs (Admin::BlogsController)" do
    it "cannot create a blog post" do
      expect do
        post admin_blogs_path, params: { blog: { title: "Volunteer post", content: "Hello" } }
      end.not_to change(Blog, :count)
    end

    it "cannot update a blog post" do
      blog = create(:blog, title: "Original")

      patch admin_blog_path(blog), params: { blog: { title: "Changed" } }

      expect(blog.reload.title).to eq("Original")
    end

    it "cannot delete a blog post" do
      blog = create(:blog)

      expect { delete admin_blog_path(blog) }.not_to change(Blog, :count)
    end
  end

  describe "opening hours (Admin::OpeningHoursController)" do
    it "cannot replace the weekly schedule" do
      create(:opening_hour, day: :lundi, open_at: "14:00", close_at: "22:00", updated_by_user: create(:user, :admin))
      valid_week = %w[mardi mercredi jeudi vendredi samedi dimanche].each_with_object({}) do |day, params|
        params.merge!("open_hour_#{day}" => "14", "open_minute_#{day}" => "0",
                      "close_hour_#{day}" => "22", "close_minute_#{day}" => "0")
      end

      patch admin_opening_hours_path, params: valid_week.merge(closed_lundi: "1")

      expect(OpeningHour.find_by(day: :lundi)).not_to be_closed
    end
  end

  describe "notepad (Admin::NotepadsController)" do
    it "cannot overwrite the notepad" do
      Rails.cache.write("notepad", "Original")

      patch admin_notepad_path, params: { notepad: "Changed by volunteer" }

      expect(Rails.cache.read("notepad")).to eq("Original")
    end
  end
end
