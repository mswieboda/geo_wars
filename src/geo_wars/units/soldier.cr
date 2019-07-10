require "./unit"

module GeoWars
  class Units::Soldier < Units::Unit
    MAX_MOVEMENT = 5

    def initialize(x, y, max_movement = MAX_MOVEMENT)
      super
    end
  end
end
