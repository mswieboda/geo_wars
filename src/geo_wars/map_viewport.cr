module GeoWars
  class MapViewport
    getter width : Int32
    getter height : Int32
    getter x : Int32
    getter y : Int32
    getter cell_size : Int32

    CELL_THRESHOLD = 1

    def initialize(@width, @height, @cell_size)
      @x = @y = 0
    end

    def update(cursor : Cursor, cells_x : Int32, cells_y : Int32)
      if real_x(cursor.x) >= width - cell_size * CELL_THRESHOLD
        @x = (cursor.x * cell_size) - width + cell_size + cell_size * CELL_THRESHOLD
      elsif real_x(cursor.x) <= cell_size * CELL_THRESHOLD
        @x = (cursor.x * cell_size) - cell_size * CELL_THRESHOLD
      end

      if real_y(cursor.y) >= height - cell_size * CELL_THRESHOLD
        @y = (cursor.y * cell_size) - height + cell_size + cell_size * CELL_THRESHOLD
      elsif real_y(cursor.y) <= cell_size * CELL_THRESHOLD
        @y = (cursor.y * cell_size) - cell_size * CELL_THRESHOLD
      end

      @x = x.clamp(-cell_size, cells_x * cell_size - width + cell_size)
      @y = y.clamp(-cell_size, cells_y * cell_size - height + cell_size)
    end

    def viewable_cell?(x, y, w, h)
      x *= cell_size
      y *= cell_size

      (x >= @x || x + w >= @x) && x < @x + width && (y >= @y || y + h >= @y) && y < @y + height
    end

    def real_x(cell_x)
      (cell_x * cell_size) - @x
    end

    def real_y(cell_y)
      (cell_y * cell_size) - @y
    end

    def draw
      5.times do |num|
        LibRay.draw_rectangle_lines(
          pos_x: num,
          pos_y: num,
          width: (@width - num * 2),
          height: (@height - num * 2),
          color: LibRay::MAGENTA
        )
      end
    end
  end
end
