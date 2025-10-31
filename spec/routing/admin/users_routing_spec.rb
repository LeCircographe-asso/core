require "rails_helper"

RSpec.describe "Admin Users routing", type: :routing do
  describe "refactored routes" do
    it "routes to index_refactored", :disabled do
      expect(get: "/admin/users/index_refactored")
        .to route_to("admin/users#index_refactored")
    end

    it "routes to index_viewcomponents", :disabled do
      expect(get: "/admin/users/index_viewcomponents")
        .to route_to("admin/users#index_viewcomponents")
    end
  end

  describe "specialized controller routes" do
    it "routes to duplicates index" do
      expect(get: "/admin/users/duplicates")
        .to route_to("admin/users#duplicates")
    end

    # Note: duplicates merge route not yet implemented
    # it "routes to duplicates merge" do
    #   expect(post: "/admin/users/duplicates/merge")
    #     .to route_to("admin/users/duplicates#merge")
    # end
  end

  describe "route helpers" do
    it "generates correct helper for index_refactored", :disabled do
      expect(index_refactored_admin_users_path).to eq("/admin/users/index_refactored")
    end

    it "generates correct helper for index_viewcomponents", :disabled do
      expect(index_viewcomponents_admin_users_path).to eq("/admin/users/index_viewcomponents")
    end

    it "generates correct helper for duplicates" do
      expect(duplicates_admin_users_path).to eq("/admin/users/duplicates")
    end
  end

  describe "standard CRUD routes" do
    it "routes to index" do
      expect(get: "/admin/users")
        .to route_to("admin/users#index")
    end

    it "routes to show" do
      expect(get: "/admin/users/1")
        .to route_to("admin/users#show", id: "1")
    end

    it "routes to new" do
      expect(get: "/admin/users/new")
        .to route_to("admin/users#new")
    end

    it "routes to create" do
      expect(post: "/admin/users")
        .to route_to("admin/users#create")
    end

    it "routes to edit" do
      expect(get: "/admin/users/1/edit")
        .to route_to("admin/users#edit", id: "1")
    end

    it "routes to update" do
      expect(patch: "/admin/users/1")
        .to route_to("admin/users#update", id: "1")
    end

    it "routes to destroy" do
      expect(delete: "/admin/users/1")
        .to route_to("admin/users#destroy", id: "1")
    end
  end
end
