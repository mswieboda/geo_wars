require "./unit"

module GeoWars
  class Units::Soldier < Units::Unit
    MAX_MOVEMENT = 5

    DEFAULT_DAMAGE = 6

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
      "Soldier"
    end
  end
end
