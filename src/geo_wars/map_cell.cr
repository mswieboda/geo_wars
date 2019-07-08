module GeoWars
  class MapCell
    BORDER_COLOR      = LibRay::DARKGRAY
    BORDER_INSET_SIZE = 0

    def initialize(@x : Int32, @y : Int32, @terrain : Terrain)
    end

    def update
    end

    def draw(size)
      # terrain
      LibRay.draw_rectangle(
        pos_x: @x * size,
        pos_y: @y * size,
        width: size,
        height: size,
        color: @terrain.color
      )

      # border
      LibRay.draw_rectangle_lines(
        pos_x: @x * size + BORDER_INSET_SIZE,
        pos_y: @y * size + BORDER_INSET_SIZE,
        width: size - BORDER_INSET_SIZE * 2,
        height: size - BORDER_INSET_SIZE * 2,
        color: BORDER_COLOR
      )
    end
  end
end
