# frozen_string_literal: true

require "rails_helper"

# Renders every parameterless (or person-scoped) admin GET page as a super
# admin and fails on any missing translation. Catches keys stored under the
# wrong namespace, which silently render placeholders.
RSpec.describe "Admin translations", type: :request do
  it "renders admin pages without missing translations" do
    login_as(create(:user, :super_admin))
    person = create(:person)
    create(:membership, person:)

    paths = Rails.application.routes.routes.filter_map do |route|
      path = route.path.spec.to_s.delete_suffix("(.:format)")
      next unless route.verb == "GET" && path.start_with?("/admin")

      path.gsub(/:(id|member_id|person_id)/, person.id.to_s)
    end.uniq.reject { |path| path.include?(":") || path.include?("(") }

    missing = paths.each_with_object({}) do |path, found|
      get path
      next unless response.status == 200

      keys = response.body.scan(/translation missing: ([^"<]+)/).flatten.uniq
      found[path] = keys if keys.any?
    end

    expect(missing).to eq({})
  end
end
