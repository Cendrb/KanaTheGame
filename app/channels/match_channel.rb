# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class MatchChannel < ApplicationCable::Channel
  def subscribed
    match = current_user_connected.current_match
    user = current_user_connected

    stream_from "match_" + match.id.to_s

    if user.currently_playing_in_match == match
      if !match.currently_playing
        match.currently_playing = user.current_match_signup.player
        match.save!
      end
      send_mode(:play, user.current_match_signup.player.id)
    else
      send_mode(:spectate, -1)
    end
    send_state()
    send_current_match_status('render successful', user)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def play(data)
    logger.debug('=======PLAY INVOKED=======')
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

      recalculate_fulfilled_shapes(match, current_user_connected.current_match_signup.player_id)
      match.save!
      match_signup.save!
      send_current_match_status(status)
    else
      send_current_match_status(status, current_user_connected)
    end
  end

  def refresh
    # rails use CACHE because they don't notice the change from the previous move - this force reloads the match from the database
    current_user_connected.current_match.reload
    # refresh board only for the request sender
    send_current_match_status('refresh successful', current_user_connected)
  end

  def repopulate
    match = current_user_connected.current_match
    if !match.waiting?
      match.board_data.repopulate(match.match_signups.pluck(:player_id))
      match.save!
      send_current_match_status('repopulation done')
    else
      send_current_match_status('cannot repopulate without all players present')
    end

  end

  private
# @param [String] message
# @param [User] target_user
  def send_current_match_status(message = '', target_user = nil)
    match = current_user_connected.current_match
    MatchBroadcaster.send_board_data(match, message, target_user)
  end

  private
  def send_mode(mode, player_id)
    match = current_user_connected.current_match
    MatchBroadcaster.send_mode(match, current_user_connected, mode, player_id)
  end

  def send_state
    match = current_user_connected.current_match
    MatchBroadcaster.send_state(match)
  end

  def recalculate_fulfilled_shapes(match, player_id)
    match.fulfilled_shapes.delete(match.fulfilled_shapes.where(traded: false))
    Shape.all.each do |shape|
      # this saves the object into DB
      match.fulfilled_shapes << shape.get_shapes_in_match(match, player_id)
    end
  end

end
