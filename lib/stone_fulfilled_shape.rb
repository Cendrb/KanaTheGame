class StoneFulfilledShape
  attr_accessor :player_id
  attr_accessor :id
  def initialize(id, player_id)
    super()
    @id = id
    @player_id = player_id
  end
end
