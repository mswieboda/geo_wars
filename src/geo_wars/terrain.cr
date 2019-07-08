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
  end
end
