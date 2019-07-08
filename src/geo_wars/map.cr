module GeoWars
  class Map
    property cells : Array(Array(MapCell))

    DEFAULT_CELL_SIZE = 64

    def initialize(@width = Game::SCREEN_WIDTH, @height = Game::SCREEN_HEIGHT, @cell_size = DEFAULT_CELL_SIZE)
      @cells = Array.new(@width / @cell_size) { |x| Array.new(@height / @cell_size) { |y| MapCell.new(x, y, Terrain::Field) } }

      @unit = Unit.new(5, 10)
    end

    def update
    end

    def draw
      @cells.each { |row| row.each { |cell| cell.draw(@cell_size) } }

      @unit.draw(@cell_size, LibRay::GREEN)
    end
  end
end
