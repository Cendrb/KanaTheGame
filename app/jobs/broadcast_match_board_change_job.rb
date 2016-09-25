class BroadcastMatchBoardChangeJob < ApplicationJob
  queue_as :default

  def perform(match, message = '', target = -1)
    MatchBroadcaster.send_board_data(match, message, target)
  end
end
