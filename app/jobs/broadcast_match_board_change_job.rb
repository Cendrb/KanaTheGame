class BroadcastMatchBoardChangeJob < ApplicationJob
  queue_as :default

  # @param [Match] match
  # @param [String] message
  # @param [User] target_user
  def perform(match, message = '', target_user = nil)
    MatchBroadcaster.send_board_data(match, message, target_user)
  end
end
