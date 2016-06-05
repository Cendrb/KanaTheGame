class Match < ApplicationRecord
  has_many :match_signups
  has_many :fulfilled_shapes
  has_many :users, foreign_key: 'current_match_id'
  serialize :board_data, BoardMatch
end
