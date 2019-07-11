require "./units/*"

module GeoWars
  class Map
    property turn_player : Player
    getter? editing

    @cells : Array(MapCell)
    @cells_x : Int32
    @cells_y : Int32
    @players : Array(Player)

    DEFAULT_CELL_SIZE = 64

    POSSIBLE_MOVES = (-1..1).flat_map { |x| (-1..1).map { |y| {x: x, y: y} } }.select { |move| !(move[:x] == 0 && move[:y] == 0) }

    def initialize(@cells_x, @cells_y, @players, width = Game::SCREEN_WIDTH, height = Game::SCREEN_HEIGHT, cell_size = DEFAULT_CELL_SIZE)
      @viewport = MapViewport.new(width: width, height: height, cell_size: cell_size)

      @cells = Array.new(@cells_x) { |x| Array.new(@cells_y) { |y| MapCell.new(x, y, Terrain.random) } }.flatten
      @units = [] of Units::Unit

      # testing cursor and units
      @cursor = Cursor.new(3, 3)

      @turn_player = Player.new(color: LibRay::MAGENTA)

      if @players.size > 0
        @turn_player = @players[0]
        @units << Units::Soldier.new(3, 3, @players[0])
        @units << Units::Soldier.new(5, 5, @players[0])
      end

      if @players.size > 1
        @units << Units::Soldier.new(4, 4, @players[1])
        @units << Units::Soldier.new(13, 3, @players[1])
        @units << Units::Soldier.new(15, 5, @players[1])
      end
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
        pre_selected_unit = @units.find { |unit| unit.selectable?(turn_player) && @cursor.selected?(unit.x, unit.y) }

        if pre_selected_unit
          pre_selected_unit.select(@cells, @cells_x, @cells_y)
        else
          @units.select(&.selected?).each(&.unselect)
        end
      elsif @cursor.selection_cancel?
        @units.select(&.selected?).each(&.unselect)
      end

      if selected_unit
        if Keys.pressed?(Keys::ACCEPT)
          cell = @cells.find { |cell| @cursor.selected?(cell.x, cell.y) }

          if cell && selected_unit.move(cell)
            selected_unit.unselect
          end
        end
      end

      @units.each { |unit| unit.update(frame_time) }

      editor_update(frame_time)
    end

    def editor_update(frame_time)
      @editing = !@editing if Keys.pressed?(LibRay::KEY_F1)

      return unless editing?

      import_map if Keys.pressed?(LibRay::KEY_F2)
      export_map if Keys.pressed?(LibRay::KEY_F3)

      set_terrain(Terrain::Field) if Keys.down?(LibRay::KEY_ONE)
      set_terrain(Terrain::Forest) if Keys.down?(LibRay::KEY_TWO)
      set_terrain(Terrain::Road) if Keys.down?(LibRay::KEY_THREE)
      set_terrain(Terrain::Water) if Keys.down?(LibRay::KEY_FOUR)
      set_terrain(Terrain::Mountain) if Keys.down?(LibRay::KEY_FIVE)
      flip_terrain if Keys.pressed?(Keys::TILDE)
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

    def new_player_turn
      @units.select(&.disabled?).each(&.enable)
    end

    def draw
      @cells.each { |cell| cell.draw(@viewport) }

      @units.each { |unit| unit.draw(@viewport) }

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
      # TODO: need to serialize and deserialize player object info
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
      @units = Array(Units::Unit).new

      lines.each do |line|
        if line.starts_with?("mc:")
          @cells << MapCell.deserialize(line)
        elsif line.starts_with?("u:")
          # TODO: need to serialize and deserialize player object info
          @units << Units::Unit.deserialize(line, @players[0])
        end
      end
    end
  end
end
