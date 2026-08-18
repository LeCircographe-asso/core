# frozen_string_literal: true

module Backups
  class NightlySnapshotJob < ApplicationJob
    queue_as :default

    def perform
      result = Backups::NightlySnapshotService.new.call

      Rails.logger.error("[Backups::NightlySnapshotJob] #{result.message}") unless result.success?
    end
  end
end
