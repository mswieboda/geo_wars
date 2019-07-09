module GeoWars
  class MapCell
    BORDER_COLOR      = LibRay::DARKGRAY
    BORDER_INSET_SIZE = 0

    def initialize(@x : Int32, @y : Int32, @terrain : Terrain)
    end

    def update
    end

    def draw(viewport)
      width = viewport.cell_size
      height = viewport.cell_size

      return unless viewport.viewable_cell?(@x, @y, width, height)

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      # terrain
      LibRay.draw_rectangle(
        pos_x: x,
        pos_y: y,
        width: width,
        height: height,
        color: @terrain.color
      )

      return unless Game::DEBUG

      # border
      LibRay.draw_rectangle_lines(
        pos_x: x + BORDER_INSET_SIZE,
        pos_y: y + BORDER_INSET_SIZE,
        width: width - BORDER_INSET_SIZE * 2,
        height: height - BORDER_INSET_SIZE * 2,
        color: BORDER_COLOR
      )
    end
  end
end
