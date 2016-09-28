class MatchSignup < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :user

  validates_presence_of :match, :player, :user

  after_initialize :setup_defaults

  def setup_defaults
    self.spent_points  ||= 0
  end

  def as_json(options)
    return {user_name: user.nickname}.merge(super(options))
  end
end
