module GeoWars
  class Units::Unit
    getter x : Int32
    getter y : Int32
    getter player : Player
    getter? selected
    getter? disabled

    SIZE_RATIO = 0.5

    SELECTED_BORDER_TIMER = 0.75
    SELECTED_BORDER_COLOR = LibRay::BLACK

    SELECTED_BORDER_SIZE_RATIO = 16

    MAX_MOVEMENT          = 3
    MOVEMENT_RADIUS_COLOR = LibRay::Color.new(r: 255, g: 255, b: 255, a: 125)

    DISABLED_DARKNESS = 0.325

    def initialize(@x, @y, @player, @max_movement = MAX_MOVEMENT)
      @selected = false
      @selected_border_timer = Timer.new(SELECTED_BORDER_TIMER)
      @moves_relative = Array(NamedTuple(x: Int32, y: Int32)).new
      @moves_relative_initial = [
        {x: 0, y: -1},
        {x: -1, y: 0},
        {x: 0, y: 0},
        {x: 0, y: 1},
        {x: 1, y: 0},
      ]
    end

    def update(frame_time)
      if selected?
        if @selected_border_timer.done?
          @selected_border_timer.reset
        end

        @selected_border_timer.increase(frame_time)
      end
    end

    def draw(viewport)
      width = viewport.cell_size * SIZE_RATIO
      height = viewport.cell_size * SIZE_RATIO

      return unless viewport.viewable_cell?(@x, @y, width, height)

      draw_movement_radius(viewport) if selected?

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      color = player.color

      if disabled?
        color = LibRay::Color.new(
          r: color.r * DISABLED_DARKNESS,
          g: color.g * DISABLED_DARKNESS,
          b: color.b * DISABLED_DARKNESS,
          a: 255
        )
      end

      LibRay.draw_rectangle(
        pos_x: x + (viewport.cell_size - width) / 2,
        pos_y: y + (viewport.cell_size - height) / 2,
        width: width,
        height: height,
        color: color
      )

      if selected?
        if @selected_border_timer.toggle?
          (viewport.cell_size / SELECTED_BORDER_SIZE_RATIO).times do |num|
            LibRay.draw_rectangle_lines(
              pos_x: x + num + (viewport.cell_size - width) / 2,
              pos_y: y + num + (viewport.cell_size - height) / 2,
              width: width - num * 2,
              height: height - num * 2,
              color: SELECTED_BORDER_COLOR
            )
          end
        end
      end
    end

    def draw_movement_radius(viewport)
      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      @moves_relative.each do |move|
        LibRay.draw_rectangle(
          pos_x: x + move[:x] * viewport.cell_size,
          pos_y: y + move[:y] * viewport.cell_size,
          width: viewport.cell_size,
          height: viewport.cell_size,
          color: MOVEMENT_RADIUS_COLOR
        )
        LibRay.draw_rectangle_lines(
          pos_x: x + move[:x] * viewport.cell_size,
          pos_y: y + move[:y] * viewport.cell_size,
          width: viewport.cell_size,
          height: viewport.cell_size,
          color: SELECTED_BORDER_COLOR
        )
      end
    end

    def update_moves(cells, cells_x, cells_y)
      # TODO: not sure why it should be @max_movement + 1, check into this
      @moves_relative = add_moves(@moves_relative_initial, @max_movement + 1, cells, cells_x, cells_y)
    end

    def add_moves(moves, moves_left, cells, cells_x, cells_y)
      child_moves = [] of NamedTuple(x: Int32, y: Int32)

      return child_moves if moves_left <= 0 || moves.empty?

      moves.each do |move_relative|
        child_moves_left = moves_left
        move = move_absolute(move_relative)

        in_bounds = move[:x] >= 0 && move[:x] < cells_x && move[:y] >= 0 && move[:y] < cells_y

        if in_bounds
          cell = cells.find { |c| c.x == move[:x] && c.y == move[:y] }

          if cell
            terrain_moves = terrain_moves(cell.terrain)

            if terrain_moves > 0
              child_moves_left -= terrain_moves
              moveable = child_moves_left > 0

              # don't pass through a mountain in one whole move
              child_moves_left = 0 unless cell.terrain.passable?
            else
              moveable = false
            end

            if moveable
              child_moves << move_relative

              more_moves = @moves_relative_initial.map { |m| {x: m[:x] + move_relative[:x], y: m[:y] + move_relative[:y]} }

              child_moves += add_moves(more_moves, child_moves_left, cells, cells_x, cells_y).uniq
            end
          end
        end
      end

      return child_moves.uniq
    end

    def terrain_moves(terrain)
      terrain.moves
    end

    def move_absolute(move)
      {x: move[:x] + @x, y: move[:y] + @y}
    end

    def moves
      @moves_relative.map { |move| move_absolute(move) }
    end

    def jump_to(x, y)
      @x = x
      @y = y
    end

    def move(cell)
      return false if cell.unit?

      cell.unit = self

      # TODO: animate allow selected path
      jump_to(cell.x, cell.y)

      disable unless can_attack?
    end

    def can_attack?
      # TODO: not yet implemented
    end

    def selectable?(turn_player)
      return false if disabled?

      player == turn_player
    end

    def select(cells, cells_x, cells_y)
      return if disabled?

      @selected = !@selected

      update_moves(cells, cells_x, cells_y)
    end

    def unselect
      @selected = false
    end

    def disable
      @disabled = true
    end

    def enable
      @disabled = false
    end

    def serialize(players)
      player_index = players.index(player)

      class_info = Map.serialize_class_info(self)
      object_info = "#{@x},#{@y},#{player_index}"

      "#{class_info};#{object_info}"
    end

    def self.deserialize(line, players)
      class_info, obj_info = line.split(";")
      x, y, player_index = obj_info.split(",").map(&.to_i)

      unless class_info.starts_with?("u:")
        raise "Error: not a serialized Unit, data line: #{line}"
      end

      sub_class_info = class_info.split(":").last

      case sub_class_info
      when .starts_with?("s")
        Units::Soldier.new(x, y, players[player_index])
      else
        Units::Unit.new(x, y, players[player_index])
      end
    end
  end
end
