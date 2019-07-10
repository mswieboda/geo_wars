module GeoWars
  enum Terrain
    Field
    Road
    Water
    Mountain

    def color
      case self
      when Field
        LibRay::DARKGREEN
      when Road
        LibRay::GRAY
      when Water
        LibRay::BLUE
      when Mountain
        LibRay::DARKGRAY
      else
        LibRay::BLANK
      end
    end

    def moves
      case self
      when Field
        1
      when Road
        1
      when Water
        0
      when Mountain
        2
      else
        0
      end
    end

    def self.random
      Terrain.values.sample
    end
  end
end
