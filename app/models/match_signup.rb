class MatchSignup < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :user
end
