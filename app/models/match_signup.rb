class MatchSignup < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :user

  validates_presence_of :match, :player, :user
end
