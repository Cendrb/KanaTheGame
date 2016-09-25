class MatchBroadcaster
  def MatchBroadcaster.send_board_data(match, message = '', target = -1)
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 board_data: BoardMatch.dump(match.board_data),
                                 mode: 'board_render',
                                 signups: match.match_signups.to_json,
                                 message: message,
                                 currently_playing: match.currently_playing.id,
                                 target: target
  end

  def MatchBroadcaster.send_state(match)
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 mode: 'set_state',
                                 state: match.state
  end

  def MatchBroadcaster.send_mode(match, user_to_set_mode_for, mode)
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 mode: 'set_mode',
                                 player_mode: mode,
                                 user_id: user_to_set_mode_for.id
  end
end