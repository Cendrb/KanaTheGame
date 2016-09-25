class BroadcastMatchStateChangeJob < ApplicationJob
  queue_as :default

  # @param [Match] match
  def perform(match)
    MatchBroadcaster.send_state(match)
  end
end
