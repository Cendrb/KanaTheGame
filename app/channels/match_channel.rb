# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class MatchChannel < ApplicationCable::Channel
  def subscribed
    Match.find(4).signup_user(current_user)
    match = current_user.current_match
      if !match.currently_playing
      puts current_user.current_match_signup.player.to_yaml
      match.currently_playing = current_user.current_match_signup.player
      match.save!
    end
    stream_from "match_" + current_user.current_match.id.to_s
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def play(data)
    logger.debug('=======PLAY INVOKED=======')
    match = current_user.current_match
    match_signup = current_user.current_match_signup
    source_x = data['sourceX']
    source_y = data['sourceY']
    target_x = data['targetX']
    target_y = data['targetY']

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

      match.save!
      match_signup.save!
    end

    send_current_match_status(status)
  end

  def refresh
    send_current_match_status('render successful')
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
  def send_current_match_status(message = '')
    match = current_user.current_match
    ActionCable.server.broadcast "match_" + match.id.to_s,
                                 board_data: BoardMatch.dump(match.board_data),
                                 mode: 'board_render', signups: match.match_signups.to_json,
                                 message: message,
                                 currently_playing: match.currently_playing.id,
                                 this_player_id: current_user.current_match_signup.player.id
  end
end
