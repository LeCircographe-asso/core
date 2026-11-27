# frozen_string_literal: true

module Imports
  # Import progress shared between the (synchronous) import request and the
  # modal polling it. Scoped per user so a token cannot read someone else's run.
  class Progress
    TOKEN_FORMAT = /\A[0-9a-f-]{36}\z/
    WRITE_EVERY = 10
    TTL = 10.minutes

    def initialize(user:, token:)
      @key = "imports/progress/#{user.id}/#{token}" if token.to_s.match?(TOKEN_FORMAT)
    end

    def update(processed, total)
      return unless @key
      return unless (processed % WRITE_EVERY).zero? || processed == total

      Rails.cache.write(@key, { processed:, total: }, expires_in: TTL)
    end

    def read
      (@key && Rails.cache.read(@key)) || { processed: 0, total: nil }
    end
  end
end
