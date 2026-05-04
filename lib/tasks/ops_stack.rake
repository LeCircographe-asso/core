# frozen_string_literal: true

namespace :ops do
  desc "Verify Solid Cable / SQLite wiring (run on staging or locally after db:migrate)."
  task cable_check: :environment do
    cable_cfg = Rails.application.config_for(:cable)
    adapter = cable_cfg[:adapter].to_s

    unless adapter == "solid_cable"
      puts "ops:cable_check — adapter is #{adapter.inspect}, skipping Solid Cable checks."
      next
    end

    connects = SolidCable.connects_to
    if connects.blank?
      abort "Solid Cable adapter is solid_cable but connects_to is missing — add to config/cable.yml under #{Rails.env}."
    end

    unless SolidCable::Message.table_exists?
      abort "solid_cable_messages missing — run: bin/rails db:migrate (includes db/cable_migrate)."
    end

    count = SolidCable::Message.count
    puts "ops:cable_check — OK (#{Rails.env}, solid_cable_messages rows=#{count})."
  end
end
