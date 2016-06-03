class Player < ApplicationRecord
  has_many :match_signups

  validates_presence_of :color, :name, :priority
  validates_uniqueness_of :color, :name, :priority
end
