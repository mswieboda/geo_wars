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

    def initialize(@cells_x, @cells_y, @players, width = Game::SCREEN_WIDTH, height = Game::SCREEN_HEIGHT, cell_size = DEFAULT_CELL_SIZE, map_file = "map")
      @viewport = MapViewport.new(width: width, height: height, cell_size: cell_size)

      @cells = Array.new(@cells_x) { |x| Array.new(@cells_y) { |y| MapCell.new(x, y, Terrain.random) } }.flatten
      @units = [] of Units::Unit

      @cursor = Cursor.new(0, 0)

      @turn_player = Player.new(color: LibRay::MAGENTA)

      if @players.size > 0
        @turn_player = @players[0]
      end

      begin
        load(map_file)
      rescue
        if @players.size > 0
          @units << Units::Soldier.new(3, 3, @players[0])
          @units << Units::Soldier.new(5, 5, @players[0])
        end

        if @players.size > 1
          @units << Units::Soldier.new(4, 4, @players[1])
          @units << Units::Soldier.new(13, 3, @players[1])
          @units << Units::Soldier.new(15, 5, @players[1])
        end
      end
    end

    def update(frame_time)
      selected_unit = @units.find(&.selected?)

      # valid move delta, removing out of map boundaries (negative values already clamped in Cursor#movement)
      valid_move_deltas = POSSIBLE_MOVES.select { |m| @cursor.x + m[:x] < @cells_x && @cursor.y + m[:y] < @cells_y }

      @cursor.update(frame_time, valid_move_deltas)
      @viewport.update(@cursor, @cells_x, @cells_y)

      if @cursor.selection?
        if selected_unit
          if selected_unit.move(@cursor, @cells)
            selected_unit.unselect
          end
        else
          # select a new unit
          pre_selected_unit = @units.find { |unit| unit.selectable?(turn_player) && @cursor.selected?(unit.x, unit.y) }

          if pre_selected_unit
            pre_selected_unit.select(@cells, @cells_x, @cells_y)
          end
        end
      elsif @cursor.selection_cancel?
        # deselect a selected unit
        selected_unit.unselect if selected_unit
      end

      @units.each { |unit| unit.update(frame_time) }
      # @units.select(&.remove?).each { |u| }
      @units.reject!(&.remove?)

      editor_update(frame_time)
    end

    def selected_cell
      selected_cell = @cells.find { |cell| @cursor.selected?(cell.x, cell.y) }

      unless selected_cell
        raise "Error: Map#selected_cell, couldn't find cell from cursor: (#{@cursor.x}, #{@cursor.y})"
      end

      selected_cell.as(MapCell)
    end

    def update_cells
      @cells.select(&.unit?).each(&.clear_unit)

      @cells.each do |cell|
        unit = @units.find { |u| u.x == cell.x && u.y == cell.y }

        if unit
          cell.unit = unit
        end
      end
    end

    def editor_update(frame_time)
      @editing = !@editing if Keys.pressed?(LibRay::KEY_F1)

      return unless editing?

      load if Keys.pressed?(LibRay::KEY_F2)
      save if Keys.pressed?(LibRay::KEY_F3)

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
      @units.each(&.turn_reset)
    end

    def draw
      @cells.each { |cell| cell.draw(@viewport) }

      selected_unit = @units.find(&.selected?)

      if selected_unit
        selected_unit.draw_movement_radius(@viewport)
        selected_unit.draw_attack_radius(@viewport)
      end

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

    def save(map_file = "map")
      path = "./build/maps/#{map_file}.gw_map"

      cells = @cells.map(&.serialize).join("\n")
      units = @units.map { |u| u.serialize(@players) }.join("\n")
      cursor = @cursor.serialize
      map_data = [cells, units, cursor].join("\n")

      Dir.mkdir("./build") unless File.exists?("./build")
      Dir.mkdir("./build/maps") unless File.exists?("./build/maps")

      file = File.write(path, map_data)

      puts "map saved! #{path}"
    end

    def load(map_file = "map")
      path = "./build/maps/#{map_file}.gw_map"
      lines = File.read_lines(path)

      cursor = nil
      cells = Array(MapCell).new
      units = Array(Units::Unit).new

      lines.each do |line|
        if line.starts_with?("mc")
          cells << MapCell.deserialize(line)
        elsif line.starts_with?("u")
          units << Units::Unit.deserialize(line, @players)
        elsif line.starts_with?("c")
          cursor = Cursor.deserialize(line)
        end
      end

      @cells = cells
      @units = units

      if cursor
        @cursor = cursor
      end

      puts "map loaded! #{path}"

      update_cells
    end

    def self.serialize_class_info(obj)
      obj
        .class
        .name
        .sub("GeoWars::", "")
        .underscore
        .split("::")
        .map { |class_name| class_name.underscore.split("_").map { |camel_case_section| camel_case_section[0] }.join("") }
        .join(":")
    end
  end
end
