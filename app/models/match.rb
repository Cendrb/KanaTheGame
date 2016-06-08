class Match < ApplicationRecord
  has_many :match_signups
  has_many :fulfilled_shapes
  serialize :board_data, BoardMatch

  belongs_to :currently_playing, class_name: 'Player', foreign_key: 'currently_playing_id', required: false

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
