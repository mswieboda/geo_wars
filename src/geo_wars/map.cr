module GeoWars
  class Map
    property cells : Array(Array(MapCell))

    @cells_x : Int32
    @cells_y : Int32

    DEFAULT_CELL_SIZE = 64

    def initialize(@cells_x, @cells_y, width = Game::SCREEN_WIDTH, height = Game::SCREEN_HEIGHT, cell_size = DEFAULT_CELL_SIZE)
      @viewport = MapViewport.new(width: width, height: height, cell_size: cell_size)

      @cells = Array.new(@cells_x) { |x| Array.new(@cells_y) { |y| MapCell.new(x, y, Terrain.random) } }

      @cursor = Cursor.new(3, 3)

      @units = [] of Unit
      @units << Unit.new(3, 3)
      @units << Unit.new(5, 5)
    end

    def update(frame_time)
      @viewport.update(@cursor, @cells_x, @cells_y, frame_time)

      if @cursor.selection?
        selected_unit = @units.find { |unit| @cursor.selected?(unit.x, unit.y) }

        if selected_unit
          @units.select { |u| u != selected_unit && u.selected? }.each(&.unselect)
          selected_unit.select
        else
          @units.select(&.selected?).each(&.unselect)
        end
      end

      @units.each { |unit| unit.update(frame_time) }
    end

    def draw
      @cells.each { |row| row.each { |cell| cell.draw(@viewport) } }

      @units.each { |unit| unit.draw(@viewport, LibRay::GREEN) }

      @cursor.draw(@viewport)
      @viewport.draw
    end
  end
end
