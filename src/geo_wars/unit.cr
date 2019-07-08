module GeoWars
  class Unit
    SIZE_RATIO = 0.5

    def initialize(@x : Int32, @y : Int32)
    end

    def update
    end

    def draw(size, color)
      # border
      LibRay.draw_rectangle(
        pos_x: @x * size + (size - size * SIZE_RATIO) / 2,
        pos_y: @y * size + (size - size * SIZE_RATIO) / 2,
        width: size * SIZE_RATIO,
        height: size * SIZE_RATIO,
        color: color
      )
    end
  end
end
