module GeoWars
  class Map
    property cells : Array(MapCell)

    @cells_x : Int32
    @cells_y : Int32

    DEFAULT_CELL_SIZE = 64

    def initialize(@cells_x, @cells_y, width = Game::SCREEN_WIDTH, height = Game::SCREEN_HEIGHT, cell_size = DEFAULT_CELL_SIZE)
      @viewport = MapViewport.new(width: width, height: height, cell_size: cell_size)

      @cells = Array.new(@cells_x) { |x| Array.new(@cells_y) { |y| MapCell.new(x, y, Terrain.random) } }.flatten

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

      if LibRay.key_pressed?(LibRay::KEY_F1)
        export_map
      end

      if LibRay.key_pressed?(LibRay::KEY_F2)
        import_map
      end
    end

    def draw
      @cells.each { |cell| cell.draw(@viewport) }

      @units.each { |unit| unit.draw(@viewport, LibRay::GREEN) }

      @cursor.draw(@viewport)
      @viewport.draw
    end

    def export_map
      cells = @cells.map(&.serialize).join("\n")
      units = @units.map(&.serialize).join("\n")
      map = [cells, units].join("\n")

      Dir.mkdir("./build") unless File.exists?("./build")
      Dir.mkdir("./build/maps") unless File.exists?("./build/maps")
      File.write("./build/maps/map.gw_map", map)
    end

    def import_map
      lines = File.read_lines("./build/maps/map.gw_map")

      @cells = Array(MapCell).new
      @units = Array(Unit).new

      lines.each do |line|
        if line.starts_with?("mc:")
          @cells << MapCell.deserialize(line)
        elsif line.starts_with?("u:")
          @units << Unit.deserialize(line)
        end
      end
    end
  end
end
