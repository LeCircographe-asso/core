# frozen_string_literal: true

module NewsletterParamParser
  private

  # Returns nil when newsletter key is absent, to avoid implicit unsubscribe.
  def extract_newsletter_subscribed!(source_params:, person_params:)
    newsletter_explicit = source_params.key?(:newsletter_subscribed)
    newsletter_flag = person_params.delete(:newsletter_subscribed)
    return nil unless newsletter_explicit

    [ "1", true, 1 ].include?(newsletter_flag)
  end
end
