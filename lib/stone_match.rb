class StoneMatch
  attr_accessor :player_id
  attr_accessor :id
  def initialize(id, player_id)
    super()
    @player_id = player_id
    @id = id
  end
end