module GeoWars
  class Units::Unit
    getter x : Int32
    getter y : Int32
    getter? selected

    SIZE_RATIO = 0.5

    SELECTED_BORDER_TIMER = 0.75
    SELECTED_BORDER_COLOR = LibRay::BLACK

    SELECTED_BORDER_SIZE_RATIO = 16

    MAX_MOVEMENT          = 3
    MOVEMENT_RADIUS_COLOR = LibRay::Color.new(r: 255, g: 255, b: 255, a: 125)

    def initialize(@x, @y, @max_movement = MAX_MOVEMENT)
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

    def draw(viewport, color)
      width = viewport.cell_size * SIZE_RATIO
      height = viewport.cell_size * SIZE_RATIO

      return unless viewport.viewable_cell?(@x, @y, width, height)

      draw_movement_radius(viewport) if selected?

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

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
      @moves_relative = @moves_relative_initial.select do |move_realtive|
        moves = @max_movement
        move = move_absolute(move_realtive)
        cell = cells.find { |c| c.x == move[:x] && c.y == move[:y] }

        if cell
          in_bounds = move[:x] >= 0 && move[:x] < cells_x && move[:y] >= 0 && move[:y] < cells_y

          terrain_moves = terrain_moves(cell.terrain)

          if terrain_moves > 0
            moves -= terrain_moves
            moveable = moves > 0
          else
            moveable = false
          end

          in_bounds && moveable
        else
          false
        end
      end
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

    def move(x, y)
      @x = x
      @y = y
    end

    def select(cells, cells_x, cells_y)
      @selected = !@selected

      update_moves(cells, cells_x, cells_y)
    end

    def unselect
      @selected = false
    end

    def serialize
      "u:#{@x},#{@y}"
    end

    def self.deserialize(line)
      x, y = line.split(":").last.split(",").map(&.to_i)
      Units::Soldier.new(x, y)
    end
  end
end
