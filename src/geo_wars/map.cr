module GeoWars
  class Map
    property cells : Array(Array(MapCell))

    @cells_x : Int32
    @cells_y : Int32

    DEFAULT_CELL_SIZE = 64

    def initialize(@cells_x, @cells_y, width = Game::SCREEN_WIDTH, height = Game::SCREEN_HEIGHT, cell_size = DEFAULT_CELL_SIZE)
      @viewport = MapViewport.new(width: width, height: height, cell_size: cell_size)

      @cells = Array.new(@cells_x) { |x| Array.new(@cells_y) { |y| MapCell.new(x, y, Terrain.random) } }

      @unit = Unit.new(3, 3)
      @cursor = Cursor.new(3, 3)
    end

    def update
      frame_time = LibRay.get_frame_time

      @viewport.update(@cursor, @cells_x, @cells_y, frame_time)
    end

    def draw
      @cells.each { |row| row.each { |cell| cell.draw(@viewport) } }

      @unit.draw(@viewport, LibRay::GREEN)

      @cursor.draw(@viewport)
      @viewport.draw
    end
  end
end
