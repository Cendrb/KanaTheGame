class StoneShape
  attr_accessor :stone_owner_flag
  def initialize(stone_owner_flag)
    super()
    @stone_owner_flag = stone_owner_flag
  end
end