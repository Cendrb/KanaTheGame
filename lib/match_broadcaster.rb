class MatchBroadcaster

  # @param [Match] match
  # @param [String] message
  # @param [User] target_user
  def MatchBroadcaster.send_board_data(match, message = '', target_user = nil)
    if target_user.nil?
      target = -1
    else
      target = target_user.id
    end
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 board_data: BoardMatch.dump(match.board_data),
                                 mode: 'board_render',
                                 signups: match.match_signups.to_json,
                                 message: message,
                                 currently_playing: match.currently_playing.id,
                                 target_user_id: target
  end

  # @param [Match] match
    def MatchBroadcaster.send_state(match)
      ActionCable.server.broadcast "match_" + match.id.to_s,
                                   mode: 'set_state',
                                   state: match.state
    end

  # @param [Match] match
  # @param [User] target_user
  # @param [String] mode
  def MatchBroadcaster.send_mode(match, target_user, mode, player_id)
      ActionCable.server.broadcast "match_" + match.id.to_s,
                                   mode: 'set_mode',
                                   player_mode: mode,
                                   target_user_id: target_user.id,
                                   player_id: player_id
    end
end