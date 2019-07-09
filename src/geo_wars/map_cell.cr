module GeoWars
  class MapCell
    BORDER_COLOR      = LibRay::DARKGRAY
    BORDER_INSET_SIZE = 0

    def initialize(@x : Int32, @y : Int32, @terrain : Terrain)
    end

    def update
    end

    def draw(viewport)
      return unless viewport.viewable_cell?(@x, @y)

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      # terrain
      LibRay.draw_rectangle(
        pos_x: x,
        pos_y: y,
        width: viewport.cell_size,
        height: viewport.cell_size,
        color: @terrain.color
      )

      # border
      LibRay.draw_rectangle_lines(
        pos_x: x + BORDER_INSET_SIZE,
        pos_y: y + BORDER_INSET_SIZE,
        width: viewport.cell_size - BORDER_INSET_SIZE * 2,
        height: viewport.cell_size - BORDER_INSET_SIZE * 2,
        color: BORDER_COLOR
      )
    end
  end
end
