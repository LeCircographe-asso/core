# frozen_string_literal: true

require "rails_helper"

# Régression : en structure plate (`production_cache:` au premier niveau de database.yml), Rails traite
# ces clés comme des environnements distincts. `production` n'avait alors que `primary`, alors que
# production.rb / cache.yml / cable.yml exigent les bases `queue`, `cache` et `cable` : l'app ne
# démarrait pas en production, sans qu'aucun test ni staging (qui n'utilise pas Solid*) ne le voie.
RSpec.describe "config/database.yml production layout" do
  let(:configs) { ActiveRecord::Base.configurations.configs_for(env_name: "production") }

  it "declares primary, cache, queue and cable databases" do
    expect(configs.map(&:name)).to match_array(%w[primary cache queue cable])
  end

  it "keeps the replicated primary database at the path Litestream watches" do
    primary = configs.find { |config| config.name == "primary" }
    litestream_paths = YAML.safe_load(ERB.new(Rails.root.join("config/litestream.yml").read).result)["dbs"].pluck("path")

    expect(litestream_paths).to eq([ primary.database ])
  end

  it "gives every Solid database its own file and schema, and no legacy migration" do
    %w[cache queue cable].each do |name|
      config = configs.find { |c| c.name == name }

      expect(config.database).to eq("storage/production_#{name}.sqlite3")
      expect(Rails.root.join("db/#{name}_schema.rb")).to exist
      expect(Dir.glob(Rails.root.join(config.migrations_paths.first, "*.rb"))).to be_empty
    end
  end

  it "points Solid Cable at the cable database" do
    cable = YAML.safe_load(ERB.new(Rails.root.join("config/cable.yml").read).result)["production"]

    expect(cable.dig("connects_to", "database", "writing")).to eq("cable")
  end
end
