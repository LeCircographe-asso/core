# Cold start one-off : jamais appelé par db:prepare ni par un workflow de déploiement.
# Usage : kamal app exec --interactive "bin/rails db:reset_keep_reference CONFIRM=yes RAILS_ENV=production"
namespace :db do
  desc "Wipe transactional data, keep curated reference tables (CONFIRM=yes required)"
  task reset_keep_reference: :environment do
    abort "Refusé hors staging/production" unless Rails.env.staging? || Rails.env.production?
    abort "Ajoute CONFIRM=yes pour confirmer la purge" unless ENV["CONFIRM"] == "yes"

    keep_tables = %w[
      faqs board_members partners
      membership_types contribution_formulas
      opening_hours exceptional_closures
      gallery_photos blogs tag_blogs tags
    ]

    db_path = ActiveRecord::Base.connection_db_config.database
    backup_path = "#{db_path}.bak-#{Time.current.to_i}"
    FileUtils.cp(db_path, backup_path)
    puts "Backup: #{backup_path}"

    conn = ActiveRecord::Base.connection
    skip = keep_tables + %w[schema_migrations ar_internal_metadata sqlite_sequence]

    conn.disable_referential_integrity do
      (conn.tables - skip).each { |t| conn.execute("DELETE FROM #{conn.quote_table_name(t)}") }
    end

    puts "Conservé : #{keep_tables.join(', ')}. Reste purgé."
  end
end
