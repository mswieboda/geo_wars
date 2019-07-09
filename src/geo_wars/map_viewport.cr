module GeoWars
  class MapViewport
    getter width : Int32
    getter height : Int32
    getter x : Int32
    getter y : Int32
    getter cell_size : Int32

    def initialize(@width, @height, @cell_size)
      @x = @y = 0
    end

    def update(cursor : Cursor, cells_x : Int32, cells_y : Int32)
      @x = (cursor.x * cell_size - width / 2).clamp(0, cells_x * cell_size - width).to_i
      @y = (cursor.y * cell_size - height / 2).clamp(0, cells_y * cell_size - height).to_i

      puts "vp: (#{x}, #{y})"
    end

    def viewable_cell?(x, y)
      x *= cell_size
      y *= cell_size
      x >= @x && x < @x + width && y >= @y && y < @y + height
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
