module GeoWars
  class Player
    getter color : LibRay::Color
    getter? human

    def initialize(@color, @human = true)
    end
  end
end
