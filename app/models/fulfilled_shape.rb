class FulfilledShape < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :shape

  validates_presence_of :match, :player, :shape
end
