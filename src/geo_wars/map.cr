module GeoWars
  class Map
    property cells : Array(Array(MapCell))

    @cell_width : Int32
    @cell_height : Int32

    DEFAULT_CELL_SIZE = 64

    def initialize(@width = Game::SCREEN_WIDTH, @height = Game::SCREEN_HEIGHT, @cell_size = DEFAULT_CELL_SIZE)
      @cell_width = @width / @cell_size
      @cell_height = @height / @cell_size
      @cells = Array.new(@cell_width) { |x| Array.new(@cell_height) { |y| MapCell.new(x, y, Terrain::Field) } }

      @unit = Unit.new(5, 10)

      @cursor = Cursor.new(3, 13)
    end

    def update
      frame_time = LibRay.get_frame_time

      @cursor.update(@cell_width, @cell_height, frame_time)
    end

    def draw
      @cells.each { |row| row.each { |cell| cell.draw(@cell_size) } }

      @unit.draw(@cell_size, LibRay::GREEN)

      @cursor.draw(@cell_size)
    end
  end
end
