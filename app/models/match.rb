class Match < ApplicationRecord
  has_many :match_signups
  has_many :fulfilled_shapes
end
