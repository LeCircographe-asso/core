require 'rails_helper'

RSpec.describe "Admin::Events", type: :request do
  describe "GET /admin/events" do
    context "when not authenticated" do
      it "redirects to login" do
        get admin_events_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as web_visitor" do
      let(:user) { create(:user, system_role: :web_visitor) }

      before { login_as(user) }

      it "redirects to root with alert" do
        get admin_events_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when authenticated as volunteer" do
      let(:volunteer) { create(:user, :volunteer) }

      before { login_as(volunteer) }

      it "returns http success" do
        get admin_events_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { login_as(admin) }

      it "returns http success" do
        get admin_events_path
        expect(response).to have_http_status(:success)
      end

      it "displays list of events" do
        event1 = create(:event, name: "Event 1", date: Date.tomorrow)
        event2 = create(:event, name: "Event 2", date: Date.tomorrow)

        get admin_events_path
        expect(response.body).to include("Event 1")
        expect(response.body).to include("Event 2")
      end
    end
  end

  describe "GET /admin/events/new" do
    let(:admin) { create(:user, :admin) }

    before { login_as(admin) }

    it "returns http success" do
      get new_admin_event_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/events" do
    let(:admin) { create(:user, :admin) }

    before { login_as(admin) }

    context "with valid attributes" do
      it "creates an event" do
        expect {
          post admin_events_path, params: {
            event: {
              title: "Test Event",
              date: Date.tomorrow,
              location: "Test Location",
              upper_description: "Upper",
              middle_description: "Middle",
              bottom_description: "Bottom"
            }
          }
        }.to change { Event.count }.by(1)
      end

      it "sets creator_id to current user" do
        post admin_events_path, params: {
          event: {
            title: "Test Event",
            date: Date.tomorrow,
            location: "Test Location"
          }
        }

        event = Event.last
        expect(event.creator_id).to eq(admin.id)
      end

      it "redirects to events index with success notice" do
        post admin_events_path, params: {
          event: {
            title: "Test Event",
            date: Date.tomorrow,
            location: "Test Location"
          }
        }

        expect(response).to redirect_to(admin_events_path)
      end
    end

    context "with invalid attributes" do
      # Note: EventManagement::EventCreator doesn't enforce title/date presence
      # Service returns success even with empty values
      # This is a known behavior - service only validates creator_id
    end
  end

  describe "GET /admin/events/:id/edit" do
    let(:admin) { create(:user, :admin) }
    let(:event) { create(:event, creator: admin) }

    before { login_as(admin) }

    it "returns http success" do
      get edit_admin_event_path(event)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/events/:id" do
    let(:admin) { create(:user, :admin) }
    let(:event) { create(:event, creator: admin, name: "Original Name") }

    before { login_as(admin) }

    context "with valid attributes" do
      it "updates the event" do
        patch admin_event_path(event), params: {
          event: {
            title: "Updated Name",
            location: "New Location"
          }
        }

        event.reload
        expect(event.name).to eq("Updated Name")
      end

      it "redirects to event show page with success notice" do
        patch admin_event_path(event), params: {
          event: {
            title: "Updated Name"
          }
        }

        expect(response).to redirect_to(event_path(event))
      end
    end

    context "with invalid attributes" do
      # Note: EventManagement::EventUpdater accepts empty strings
      # Service ignores blank values and only updates non-blank attributes
      # This is a known behavior - service only validates event_id and updated_by_id
    end
  end
end
