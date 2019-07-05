class StoneOwnerAcceptedFlag
  MINE = 1
  OTHER_PLAYERS = 2
  NEUTRALS = 4

  def self.parse_flag(flag)
    mine, other_players, neutrals = false, false, false
    if flag / StoneOwnerAcceptedFlag::NEUTRALS >= 1
      flag = flag % StoneOwnerAcceptedFlag::NEUTRALS
      neutrals = true
    end
    if flag / StoneOwnerAcceptedFlag::OTHER_PLAYERS >= 1
      flag = flag % StoneOwnerAcceptedFlag::OTHER_PLAYERS
      other_players = true
    end
    if flag / StoneOwnerAcceptedFlag::MINE >= 1
      mine = true
    end
    return mine, other_players, neutrals
  end
end