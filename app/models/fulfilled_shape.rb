class FulfilledShape < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :shape
  serialize :board_data, BoardFulfilledShape

  validates_presence_of :match, :player, :shape
end
