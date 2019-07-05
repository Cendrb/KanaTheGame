class MatchmakingController < ApplicationController
  before_action :authenticate_registered
  before_action :no_current_match, except: [:match, :leave]
  before_action :find_match_and_authenticate, only: [:spectate, :join]

  def welcome
  end

  def lobby_list
    @data = {}
    @data[:password] = params[:password]
    if @data[:password].nil?
      @data[:waiting_matches] = Match.where(state: :waiting, match_type: :open).where('password = \'\' OR password = NULL')
      @data[:spectatable_matches] = Match.where(state: :playing, match_type: :open).where('password = \'\' OR password = NULL')
    else
      @data[:waiting_matches] = Match.where(state: :waiting, match_type: :open, password: @data[:password])
      @data[:spectatable_matches] = Match.where(state: :playing, match_type: :open, password: @data[:password])
    end

  end

  # renders match view, wait/play/spectate
  def match
    @match = Match.find(params[:id])
    if @match == current_user.current_match
      cookies.signed[:match_id] = @match.id
      render 'matchmaking/match'
    else
      render plain: "You aren't either playing or spectating in this match"
    end
  end

  def ranked_match
    match = Match.new
    match.players_count = 2
    match.match_type = :ranked
    match.board_data.height = 19
    match.board_data.width = 19
    match.save!

    match.signup_user(current_user)

    redirect_to match_path(match)
  end

  def open_match
    match = Match.new
    match.players_count = params.require(:player_count)
    match.match_type = :open
    match.board_data.height = params.require(:board_height)
    match.board_data.width = params.require(:board_width)
    match.password = params[:password]
    match.save!

    match.signup_user(current_user)

    redirect_to match_path(match)
  end

  def friendly_match
    match = Match.new
    match.players_count = params.require(:player_count)
    match.match_type = :friendly
    match.board_data.height = params.require(:board_height)
    match.board_data.width = params.require(:board_width)
    match.save!

    match.signup_user(current_user)

    redirect_to match_path(match)
  end

  def spectate
    user = current_user
    user.current_match = @match
    user.save!
    redirect_to match_path(@match)
  end

  def join
    if @match.waiting?
      @match.signup_user(current_user)
    end
    redirect_to match_path(@match)
  end

  def leave
    # for both spectating and playing in match
    user = current_user
    if user.is_playing?
      # playing
      match = user.current_match
      match_signup = user.current_match_signup
      if match.playing?
        match_signup.lost = true
        match_signup.save!
        user.current_match = nil
        user.save!
        match.test_for_finish_conditions
        render nothing: true
      else
        render plain: 'You can surrender only when the match is in progress'
      end
    else
      # spectating
      user.current_match = nil
      user.save!
      redirect_to :root
    end
  end

  private
  def no_current_match
    match = current_user.current_match
    if match && match.state != :finished
      redirect_to match_path(match), notice: 'You need to finish this match first'
    end
  end

  def find_match_and_authenticate
    @match = Match.find(params[:match_id])
    if !@match.authenticate?(params[:password])
      render plain: 'Wrong password'
    end
  end
end
