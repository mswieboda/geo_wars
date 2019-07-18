module GeoWars
  class Units::Unit
    getter x : Int32
    getter y : Int32
    getter player : Player
    getter max_movement
    getter? selected
    getter? disabled
    getter? remove

    @attack_cells_relative_initial : Array(NamedTuple(x: Int32, y: Int32))
    @hit_points_color : LibRay::Color

    SIZE_RATIO = 0.5

    SELECTED_BORDER_TIMER = 0.75
    SELECTED_BORDER_COLOR = LibRay::BLACK

    SELECTED_BORDER_SIZE_RATIO = 16

    MAX_MOVEMENT          = 3
    MOVEMENT_RADIUS_COLOR = LibRay::Color.new(r: 255, g: 255, b: 255, a: 125)

    DISABLED_DARKNESS = 0.325

    DEFAULT_ATTACK_CELLS_RELATIVE = [0, 1, -1].permutations.map { |arr| {x: arr[0], y: arr[1]} }.select { |move| (move[:x] + move[:y]).abs == 1 }

    MAX_HIT_POINTS = 10

    DEFAULT_DAMAGE = 1

    def initialize(@x, @y, @player, @max_movement = MAX_MOVEMENT, @default_damage = DEFAULT_DAMAGE, @attack_cells_relative_initial = DEFAULT_ATTACK_CELLS_RELATIVE)
      @selected = false
      @moved = false
      @attacked = false
      @remove = false
      @hit_points = MAX_HIT_POINTS
      @selected_border_timer = Timer.new(SELECTED_BORDER_TIMER)
      @moves_relative = [] of NamedTuple(x: Int32, y: Int32)
      @moves_relative_initial = [
        {x: 0, y: -1},
        {x: -1, y: 0},
        {x: 0, y: 0},
        {x: 0, y: 1},
        {x: 1, y: 0},
      ]

      @attack_cells_relative = [] of NamedTuple(x: Int32, y: Int32)

      @sprite_font = LibRay.get_default_font

      @hit_points_font_size = 16
      @hit_points_spacing = 0
      @hit_points_text = "9"
      @hit_points_color = LibRay::WHITE
      # @hit_points_measured = LibRay::Vector2.new
      @hit_points_position = LibRay::Vector2.new
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

      # draw hit points
      if @hit_points < MAX_HIT_POINTS
        LibRay.draw_text_ex(
          sprite_font: @sprite_font,
          text: @hit_points.to_s,
          position: LibRay::Vector2.new(
            x: x + @hit_points_position.x,
            y: y + @hit_points_position.y
          ),
          font_size: @hit_points_font_size,
          spacing: @hit_points_spacing,
          color: @hit_points_color
        )
      end
    end

    def draw_movement_radius(viewport)
      return if !selected? || @moved

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

    def draw_attack_radius(viewport)
      return if !selected? || !@moved || @attacked

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      @attack_cells_relative.each do |move|
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
            unit = cell.unit

            next if unit && unit.player != player

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

    def jump_to(x, y)
      @x = x
      @y = y
    end

    def move(cursor_cell, cells)
      return attack(cursor_cell, cells) if @moved && !@attacked

      return false unless valid_move?(cursor_cell, @moves_relative)

      current_cell = cells.find { |cell| cell.x == @x && cell.y == @y }

      return false if !current_cell
      return false if cursor_cell.unit? && cursor_cell.unit != self

      current_cell.clear_unit

      jump_to(cursor_cell.x, cursor_cell.y)

      cursor_cell.unit = self

      @moved = true

      update_attack_cells(cells)

      disable unless can_attack?
    end

    def valid_move?(cursor_cell, moves_relative)
      valid = @x == cursor_cell.x && @y == cursor_cell.y

      unless valid
        valid = moves_relative.any? do |move_relative|
          move = move_absolute(move_relative)
          cursor_cell.x == move[:x] && cursor_cell.y == move[:y]
        end
      end

      valid
    end

    def attack(cursor_cell, cells)
      return false if @attacked

      return false unless valid_move?(cursor_cell, @attack_cells_relative)

      current_cell = cells.find { |cell| cell.x == @x && cell.y == @y }

      return false if !current_cell
      return false unless cursor_cell.unit?

      unit = cursor_cell.unit

      if unit && unit != self
        attack(unit, cursor_cell, current_cell)

        current_cell.clear_unit if remove?
        cursor_cell.clear_unit if unit.remove?
      end

      @attacked = true

      update_attack_cells(cells)

      disable
    end

    def attack(unit : Units::Unit, unit_cell, current_cell)
      unit.take_damage(damage(unit, unit_cell))
      take_damage(unit.damage(self, current_cell))
    end

    def attack_preview_percentage(unit : Units::Unit, unit_cell)
      (100.0 * damage(unit, unit_cell) / MAX_HIT_POINTS).round.to_i
    end

    def damage(unit : Units::Unit, unit_cell)
      unit_percentage = 1.0
      power_percentage = @hit_points.to_f32 / MAX_HIT_POINTS.to_f32
      defense_percentage = unit_cell.terrain.defense_percentage
      percentage = unit_percentage * power_percentage * defense_percentage

      (@default_damage * percentage).round.to_i
    end

    def take_damage(damage)
      @hit_points -= damage

      if @hit_points <= 0
        @hit_points = 0
        die
      end
    end

    def die
      @remove = true
    end

    def update_attack_cells(cells)
      # check area for other units to attack
      @attack_cells_relative = @attack_cells_relative_initial.select do |attack_cell_relative|
        cell = cells.find { |c| c.x == @x + attack_cell_relative[:x] && c.y == @y + attack_cell_relative[:y] }

        if cell
          unit = cell.unit
          unit && unit.player != player
        else
          false
        end
      end
    end

    def can_attack?
      @attack_cells_relative.any?
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

    def turn_reset
      unselect
      enable
      @moved = false
      @attacked = false
    end

    def description
      "Unit"
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
