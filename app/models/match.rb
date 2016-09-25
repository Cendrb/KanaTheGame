class Match < ApplicationRecord
  has_many :match_signups
  has_many :fulfilled_shapes
  serialize :board_data, BoardMatch

  enum match_type: [ :ranked, :open, :friendly ]
  enum state: [ :waiting, :playing, :finished ]

  validates_presence_of :players_count, :match_type
  validates :players_count, numericality: { greater_than: 0 }

  belongs_to :currently_playing, class_name: 'Player', foreign_key: 'currently_playing_id', required: false

  def initialize(attributes = nil)
    super(attributes)
    self.board_data = BoardMatch.new
  end

  def signup_user(user)
    if !self.waiting?
      raise 'Match needs to be in waiting state for you to be able to sign up'
    end
    if user.current_match != self
      signup = MatchSignup.new
      signup.match = self
      signup.user = user
      # assign a Player object - skip already assigned ones
      signup.player = Player.order('priority DESC').offset(match_signups.count).first
      signup.save!
      user.current_match = self
      user.save!
      if self.match_signups.count >= self.players_count
        self.state = :playing
        self.save!
        BroadcastMatchStateChangeJob.perform_later(self)
        BroadcastMatchBoardChangeJob.perform_later(self, 'reached the required number of players to play')
      end
    else
      raise 'We are already part of this match!!!'
    end
  end
end
