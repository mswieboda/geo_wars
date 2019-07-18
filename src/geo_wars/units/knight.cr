require "./unit"

module GeoWars
  class Units::Knight < Units::Unit
    MAX_MOVEMENT = 8

    DEFAULT_DAMAGE = 8

    def initialize(x, y, player)
      super(
        x: x,
        y: y,
        player: player,
        max_movement: MAX_MOVEMENT,
        default_damage: DEFAULT_DAMAGE
      )
    end

    def description
      "Knight"
    end
  end
end
