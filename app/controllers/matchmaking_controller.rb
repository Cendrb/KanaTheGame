class MatchmakingController < ApplicationController
  before_action :authenticate_registered
  before_action :no_current_match, except: :match

  def welcome
  end

  def lobby_list
    @data = {}
    @data[:open_matches] = Match.joins(:match_signups).where(state: :waiting, match_type: :open)
  end

  # renders match view, wait/play/spectate
  def match
    @match = Match.find(params[:id])
    cookies.signed[:match_id] = @match.id
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
    match = Match.find(params[:match_id])
    current_user.current_match = match
    redirect_to match_path(match)
  end

  def join
    match = Match.find(params[:match_id])
    if match.waiting?
      match.signup_user(current_user)
    end
    redirect_to match_path(match)
  end

  private
  def no_current_match
    match = current_user.current_match
    if match && match.state != :finished
      redirect_to match_path(match), notice: 'You need to finish this match first'
    end
  end
end
