class Match < ApplicationRecord
  has_many :match_signups
  has_many :fulfilled_shapes
  serialize :board_data, BoardMatch

  def signup_user(user)
    if user.current_match != self
      signup = MatchSignup.new()
      signup.match = self
      signup.user = user
      if match_signups.count > 0
        signup.player = Player.order(:priority).where('priority < ?', match_signups.joins(:players).max('players.priority')).last
      else
        signup.player = Player.order(:priority).last
      end
      signup.save!
    else
      logger.fatal('We are already part of this match!!!')#raise 'We are already part of this match!!!'
    end
  end
end
