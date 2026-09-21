# frozen_string_literal: true

require "rails_helper"

# Régression : en structure plate (`production_cache:` au premier niveau de database.yml), Rails traite
# ces clés comme des environnements distincts. `production` n'avait alors que `primary`, alors que
# production.rb / cache.yml / cable.yml exigent les bases `queue`, `cache` et `cable` : l'app ne
# démarrait pas en production, sans qu'aucun test ni staging (qui n'utilisait pas Solid*) ne le voie.
# Staging partage désormais exactement la même structure pour répéter le vrai boot de la production.
RSpec.describe "config/database.yml layout of staging and production" do
  solid_databases = %w[cache queue cable].freeze

  def configs_for(env_name) = ActiveRecord::Base.configurations.configs_for(env_name: env_name)

  def yaml_for(file, env_name)
    YAML.safe_load(ERB.new(Rails.root.join("config", file).read).result, aliases: true).fetch(env_name)
  end

  %w[production staging].each do |env_name|
    context "in #{env_name}" do
      it "declares primary, cache, queue and cable databases" do
        expect(configs_for(env_name).map(&:name)).to match_array(%w[primary cache queue cable])
      end

      it "gives every Solid database its own file and schema, and no legacy migration" do
        solid_databases.each do |name|
          config = configs_for(env_name).find { |c| c.name == name }

          expect(config.database).to eq("storage/#{env_name}_#{name}.sqlite3")
          expect(Rails.root.join("db/#{name}_schema.rb")).to exist
          expect(Dir.glob(Rails.root.join(config.migrations_paths.first, "*.rb"))).to be_empty
        end
      end

      it "points Solid Cable at the cable database" do
        expect(yaml_for("cable.yml", env_name).dig("connects_to", "database", "writing")).to eq("cable")
      end

      it "points Solid Cache at the cache database" do
        expect(yaml_for("cache.yml", env_name)["database"]).to eq("cache")
      end

      it "runs jobs and cache on Solid*, like the other one" do
        source = Rails.root.join("config/environments/#{env_name}.rb").read

        expect(source).to include("config.cache_store = :solid_cache_store")
        expect(source).to include("config.active_job.queue_adapter = :solid_queue")
        expect(source).to include("config.solid_queue.connects_to = { database: { writing: :queue } }")
      end
    end
  end

  it "keeps the replicated production primary database at the path Litestream watches" do
    primary = configs_for("production").find { |config| config.name == "primary" }
    litestream_paths = YAML.safe_load(ERB.new(Rails.root.join("config/litestream.yml").read).result)["dbs"].pluck("path")

    expect(litestream_paths).to eq([ primary.database ])
  end
end
