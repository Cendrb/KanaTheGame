# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class MatchChannel < ApplicationCable::Channel
  def subscribed
    puts local_variables
    match = current_user_connected.current_match
    user = current_user_connected

    stream_from "match_" + match.id.to_s

    if user.currently_playing_in_match == match
      if !match.currently_playing
        match.currently_playing = user.current_match_signup.player
        match.save!
      end
      send_mode(:play)
    else
      send_mode(:spectate)
    end
    puts "STATE OF THI MATCH IS: #{match.state}"
    send_state(match.state)
    send_current_match_status('render successful', user.current_match_signup.player.id)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def play(data)
    logger.debug('=======PLAY INVOKED=======')
    puts current_user_connected.nickname
    match = current_user_connected.current_match
    match_signup = current_user_connected.current_match_signup
    source_x = data['sourceX']
    source_y = data['sourceY']
    target_x = data['targetX']
    target_y = data['targetY']

    # rails use CACHE because they don't notice the change from the previous move - this force reloads the match from the database
    match.reload

    puts "player signup id: #{match_signup.player_id} match currently playing id: #{match.currently_playing_id}"

    code, status = match.board_data.perform_move(source_x, source_y, target_x, target_y, match_signup.player_id, match.currently_playing_id)

    case code
      when :horizontal_vertical
        match_signup.spent_points += 3
      when :diagonal
        match_signup.spent_points += 4
      when :over_jump
        match_signup.spent_points += 5
    end
    if code != :invalid
      next_player = Player.joins(:match_signups).order('priority').where('match_signups.match_id = ?', match.id).where('priority > ?', match.currently_playing.priority).first
      if next_player
        match.currently_playing = next_player
      else
        match.currently_playing = Player.joins(:match_signups).order('priority').where('match_signups.match_id = ?', match.id).first
      end
      # TODO we somehow fail to save the currently_playing_id - it stays the same

      puts "player signup id: #{match_signup.player_id} match currently playing id: #{match.currently_playing_id}"

      match.save!
      match_signup.save!
      send_current_match_status(status)
    else
      send_current_match_status(status, current_user_connected.current_match_signup.player.id)
    end
  end

  def refresh
    send_current_match_status('render successful')
  end

  def repopulate
    match = current_user_connected.current_match
    puts match.state
    if !match.waiting?
      match.board_data.repopulate(match.match_signups.pluck(:player_id))
      match.save!
      send_current_match_status('repopulation done')
    else
      send_current_match_status('cannot repopulate without all players present')
    end

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
    ActionCable.server.broadcast "match_" + current_user_connected.match.id.to_s, board_data: BoardMatch.dump(match.board_data), mode: 'board_render'
=end
  end

  private
  def send_current_match_status(message = '', target = -1)
    match = current_user_connected.current_match
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 board_data: BoardMatch.dump(match.board_data),
                                 mode: 'board_render',
                                 signups: match.match_signups.to_json,
                                 message: message,
                                 currently_playing: match.currently_playing.id,
                                 target: target
  end

  private
  def send_mode(mode)
    match = current_user_connected.current_match
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 mode: 'set_mode',
                                 player_mode: mode,
                                 user_id: current_user_connected.id
  end

  def send_state(state)
    match = current_user_connected.current_match
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 mode: 'set_state',
                                 state: state
  end
end
