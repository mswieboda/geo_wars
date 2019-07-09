module GeoWars
  class Map
    property cells : Array(MapCell)
    getter? editing

    @cells_x : Int32
    @cells_y : Int32

    DEFAULT_CELL_SIZE = 64

    POSSIBLE_MOVES = (-1..1).flat_map { |x| (-1..1).map { |y| {x: x, y: y} } }.select { |move| !(move[:x] == 0 && move[:y] == 0) }

    def initialize(@cells_x, @cells_y, width = Game::SCREEN_WIDTH, height = Game::SCREEN_HEIGHT, cell_size = DEFAULT_CELL_SIZE)
      @viewport = MapViewport.new(width: width, height: height, cell_size: cell_size)

      @cells = Array.new(@cells_x) { |x| Array.new(@cells_y) { |y| MapCell.new(x, y, Terrain.random) } }.flatten

      @cursor = Cursor.new(3, 3)

      @units = [] of Unit
      @units << Unit.new(3, 3)
      @units << Unit.new(5, 5)
    end

    def update(frame_time)
      # valid move delta from map boundaries
      valid_move_deltas = POSSIBLE_MOVES.select { |move| @cursor.x + move[:x] < @cells_x && @cursor.y + move[:y] < @cells_y }

      selected_unit = @units.find { |unit| unit.selected? }

      if selected_unit
        valid_move_deltas.select! do |move|
          selected_unit.moves.any? do |unit_move|
            unit_move[:x] == @cursor.x + move[:x] && unit_move[:y] == @cursor.y + move[:y]
          end
        end
      end

      @cursor.update(frame_time, valid_move_deltas)
      @viewport.update(@cursor, @cells_x, @cells_y)

      if @cursor.selection?
        pre_selected_unit = @units.find { |unit| @cursor.selected?(unit.x, unit.y) }

        if pre_selected_unit
          @units.select { |u| u != pre_selected_unit && u.selected? }.each(&.unselect)
          pre_selected_unit.select
        else
          @units.select(&.selected?).each(&.unselect)
        end
      elsif @cursor.selection_cancel?
        @units.select(&.selected?).each(&.unselect)
      end

      @units.each { |unit| unit.update(frame_time) }

      editor_update(frame_time, selected_unit)
    end

    def editor_update(frame_time, selected_unit)
      @editing = !@editing if LibRay.key_pressed?(LibRay::KEY_F1)

      return unless editing?

      import_map if LibRay.key_pressed?(LibRay::KEY_F2)
      export_map if LibRay.key_pressed?(LibRay::KEY_F3)

      set_terrain(Terrain::Field) if LibRay.key_down?(LibRay::KEY_ONE)
      set_terrain(Terrain::Road) if LibRay.key_down?(LibRay::KEY_TWO)
      set_terrain(Terrain::Water) if LibRay.key_down?(LibRay::KEY_THREE)
      set_terrain(Terrain::Mountain) if LibRay.key_down?(LibRay::KEY_FOUR)
      flip_terrain if LibRay.key_pressed?(Game::KEY_TILDE)

      if selected_unit
        if LibRay.key_pressed?(LibRay::KEY_ENTER)
          selected_unit.move(@cursor.x, @cursor.y)
          selected_unit.unselect
        end
      end
    end

    def flip_terrain
      cell = @cells.find { |cell| @cursor.selected?(cell.x, cell.y) }

      if cell
        cell.terrain = cell.terrain.value == Terrain.values.last.value ? Terrain.values[0] : Terrain.values[cell.terrain.value + 1]
      end
    end

    def set_terrain(terrain)
      cell = @cells.find { |cell| @cursor.selected?(cell.x, cell.y) }

      if cell && cell.terrain != terrain
        cell.terrain = terrain
      end
    end

    def draw
      @cells.each { |cell| cell.draw(@viewport) }

      @units.each { |unit| unit.draw(@viewport, LibRay::GREEN) }

      @cursor.draw(@viewport)
      @viewport.draw

      if editing?
        LibRay.draw_rectangle(
          pos_x: 0,
          pos_y: 0,
          width: 100,
          height: 100,
          color: LibRay::MAGENTA
        )
      end
    end

    def export_map
      puts "export_map!"
      cells = @cells.map(&.serialize).join("\n")
      units = @units.map(&.serialize).join("\n")
      map = [cells, units].join("\n")

      Dir.mkdir("./build") unless File.exists?("./build")
      Dir.mkdir("./build/maps") unless File.exists?("./build/maps")
      File.write("./build/maps/map.gw_map", map)
    end

    def import_map
      puts "import_map!"
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
