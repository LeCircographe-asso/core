# frozen_string_literal: true

RSpec::Matchers.define :instrument do |expected_event_name|
  supports_block_expectations

  match do |block|
    @events = []
    @event_name = expected_event_name

    subscription = ActiveSupport::Notifications.subscribe(expected_event_name) do |*args|
      @events << args
    end

    block.call

    ActiveSupport::Notifications.unsubscribe(subscription)

    @events.any?
  end

  failure_message do |_block|
    "expected block to instrument '#{@event_name}', but it didn't. #{@events.empty? ? 'No events were fired' : "Events fired: #{@events.map(&:first)}"}"
  end

  failure_message_when_negated do |_block|
    "expected block not to instrument '#{@event_name}', but it did"
  end
end
