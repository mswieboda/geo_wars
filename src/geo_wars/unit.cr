module GeoWars
  class Unit
    SIZE_RATIO = 0.5

    def initialize(@x : Int32, @y : Int32)
    end

    def update
    end

    def draw(viewport, color)
      width = viewport.cell_size * SIZE_RATIO
      height = viewport.cell_size * SIZE_RATIO

      return unless viewport.viewable_cell?(@x, @y, width, height)

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      # border
      LibRay.draw_rectangle(
        pos_x: x + (viewport.cell_size - width) / 2,
        pos_y: y + (viewport.cell_size - height) / 2,
        width: width,
        height: height,
        color: color
      )
    end
  end
end
