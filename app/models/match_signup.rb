class MatchSignup < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :user

  validates_presence_of :match, :player, :user

  after_initialize :setup_defaults

  def setup_defaults
    self.current_points  ||= 0
  end
end
