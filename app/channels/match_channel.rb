# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class MatchChannel < ApplicationCable::Channel
  def subscribed
    Match.find(4).signup_user(current_user)
    stream_from "match_" + current_user.current_match.id.to_s
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def play
  end

  def refresh
    send_current_match_status
  end

  def give_up
=begin
    match = Match.new()
    match.board_data = BoardMatch.load({width: 10, height: 10, stones: [{x: 0, y: 1, player_id: 1},
                                                                        {x: 1, y: 1, player_id: 2},
                                                                        {x: 2, y: 1, player_id: 1},
                                                                        {x: 2, y: 0, player_id: 3},
                                                                        {x: 2, y: 4, player_id: 3},
                                                                        {x: 3, y: 3, player_id: 3},
                                                                        {x: 0, y: 3, player_id: 2}]}.to_json)
    match.started = true
    ActionCable.server.broadcast "match_" + current_user.match.id.to_s, board_data: BoardMatch.dump(match.board_data), mode: 'board_render'
=end

  end

  private
  def send_current_match_status
    ActionCable.server.broadcast "match_" + current_user.current_match.id.to_s, board_data: BoardMatch.dump(current_user.current_match.board_data), mode: 'board_render', current_points: current_user.current_match.match_signups.to_json
  end
end
