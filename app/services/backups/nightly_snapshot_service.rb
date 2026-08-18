# frozen_string_literal: true

require "open3"
require "tmpdir"

module Backups
  # Deuxième backup indépendant de Litestream (qui ne couvre que production.sqlite3
  # vers IONOS) : copie sûre de la base principale + fichiers Active Storage,
  # poussée vers Google Drive via rclone. Couvre ce que Litestream ne couvre pas
  # (fichiers uploadés) et sert de filet si IONOS/Litestream a un problème.
  # Voir docs/backup-restore.md.
  class NightlySnapshotService
    include ActiveModel::Model

    Result = Struct.new(:success?, :remote_path, :errors, :message, keyword_init: true)

    RETENTION_DAYS = 14
    RCLONE_REMOTE = "gdrive:circographe-backups"

    def call
      return failure("Only runs in production") unless Rails.env.production?

      remote_path = nil

      Dir.mktmpdir("circographe-snapshot") do |tmp_dir|
        staging_dir = build_staging_dir(tmp_dir)
        archive_path = build_archive(tmp_dir, staging_dir)
        remote_path = upload(archive_path)
      end

      prune_old_snapshots

      ActiveSupport::Notifications.instrument("backups.nightly_snapshot_uploaded", remote_path: remote_path)
      success(remote_path: remote_path, message: "Snapshot uploaded to #{remote_path}")
    rescue StandardError => e
      failure("Snapshot failed: #{e.message}")
    end

    private

    def build_staging_dir(tmp_dir)
      staging_dir = File.join(tmp_dir, "snapshot")
      FileUtils.mkdir_p(staging_dir)

      safe_copy_database(File.join(staging_dir, "production.sqlite3"))
      copy_active_storage_files(staging_dir)

      staging_dir
    end

    # `.backup` fait une copie cohérente d'une base SQLite live (contrairement à `cp`,
    # qui peut copier un fichier en cours d'écriture WAL et produire une copie corrompue).
    def safe_copy_database(destination)
      db_path = Rails.root.join("storage/production.sqlite3")
      run!("sqlite3", db_path.to_s, ".backup #{destination}")
    end

    def copy_active_storage_files(staging_dir)
      Dir.glob(Rails.root.join("storage/*")).each do |entry|
        next if File.basename(entry).include?(".sqlite3")

        FileUtils.cp_r(entry, staging_dir)
      end
    end

    def build_archive(tmp_dir, staging_dir)
      archive_path = File.join(tmp_dir, "#{Date.current.iso8601}.tar.gz")
      run!("tar", "-czf", archive_path, "-C", tmp_dir, File.basename(staging_dir))
      archive_path
    end

    def upload(archive_path)
      remote_path = "#{RCLONE_REMOTE}/#{Date.current.iso8601}.tar.gz"
      run!("rclone", "copyto", archive_path, remote_path)
      remote_path
    end

    def prune_old_snapshots
      cutoff = Date.current - RETENTION_DAYS

      list_output = run!("rclone", "lsf", RCLONE_REMOTE)
      list_output.each_line(chomp: true) do |filename|
        next unless filename.match?(/\A\d{4}-\d{2}-\d{2}\.tar\.gz\z/)

        date = Date.iso8601(filename.delete_suffix(".tar.gz"))
        run!("rclone", "deletefile", "#{RCLONE_REMOTE}/#{filename}") if date < cutoff
      end
    end

    def run!(*command)
      output, status = Open3.capture2e(*command)
      raise "#{command.first} failed: #{output}" unless status.success?

      output
    end

    def success(remote_path:, message:)
      Result.new(success?: true, remote_path: remote_path, errors: [], message: message)
    end

    def failure(message)
      Result.new(success?: false, remote_path: nil, errors: [ message ], message: message)
    end
  end
end
