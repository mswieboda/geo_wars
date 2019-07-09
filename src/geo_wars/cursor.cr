module GeoWars
  class Cursor
    getter x : Int32
    getter y : Int32
    getter? selection

    SIZE_RATIO              =    8
    SIZE_RATIO_SHRINK       =    4
    SIZE_RATIO_SHRINK_TIMER = 0.75

    KEY_DOWN_INITIAL_TIMER =   0.5
    KEY_DOWN_TIMER         = 0.125

    BORDER_WIDTH_DIVISOR = 16

    CURSOR_COLOR = LibRay::BLACK

    @key_down_initial_timers : Hash(Symbol, Timer)
    @key_down_timers : Hash(Symbol, Timer)

    def initialize(@x, @y)
      @selection = false
      @key_down_initial_timers = Hash(Symbol, Timer).new
      @key_down_timers = Hash(Symbol, Timer).new

      [:up, :left, :down, :right].each do |key|
        @key_down_initial_timers[key] = Timer.new(KEY_DOWN_TIMER)
        @key_down_timers[key] = Timer.new(KEY_DOWN_TIMER)
      end

      @size_ratio = SIZE_RATIO
      @size_ratio_shrink_timer = Timer.new(SIZE_RATIO_SHRINK_TIMER)
    end

    def update(frame_time, valid_move_deltas)
      selection_check
      movement(frame_time, valid_move_deltas)
      animation(frame_time)
    end

    def selection_check
      @selection = false

      if LibRay.key_pressed?(LibRay::KEY_SPACE)
        @selection = true
      end
    end

    def selected?(x, y)
      @x == x && @y == y
    end

    def movement(frame_time, valid_move_deltas)
      x = y = 0

      y -= 1 if keys_held?(frame_time, [LibRay::KEY_W, LibRay::KEY_UP], :up)
      x -= 1 if keys_held?(frame_time, [LibRay::KEY_A, LibRay::KEY_LEFT], :left)
      y += 1 if keys_held?(frame_time, [LibRay::KEY_S, LibRay::KEY_DOWN], :down)
      x += 1 if keys_held?(frame_time, [LibRay::KEY_D, LibRay::KEY_RIGHT], :right)

      delta = {x: x, y: y}

      # safety check, exit if not moving
      return if delta[:x] == 0 && delta[:y] == 0

      if valid_move_deltas.any? { |d| d[:x] == delta[:x] && d[:y] == delta[:y] }
        @x += delta[:x]
        @y += delta[:y]

        @x = @x.clamp(0, @x)
        @y = @y.clamp(0, @y)
      end
    end

    def animation(frame_time)
      @size_ratio_shrink_timer.increase(frame_time)
      @size_ratio = @size_ratio_shrink_timer.toggle? ? SIZE_RATIO_SHRINK : SIZE_RATIO
      @size_ratio_shrink_timer.reset if @size_ratio_shrink_timer.done?
    end

    def draw(viewport)
      width = viewport.cell_size - viewport.cell_size / @size_ratio
      height = viewport.cell_size - viewport.cell_size / @size_ratio

      return unless viewport.viewable_cell?(@x, @y, width, height)

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      (viewport.cell_size / BORDER_WIDTH_DIVISOR).times do |num|
        LibRay.draw_rectangle_lines(
          pos_x: x + num + (viewport.cell_size - width) / 2,
          pos_y: y + num + (viewport.cell_size - height) / 2,
          width: width - num * 2,
          height: height - num * 2,
          color: CURSOR_COLOR
        )
      end
    end

    def keys_held?(frame_time, keys, timer_key)
      return true if keys.any? { |key| LibRay.key_pressed?(key) }

      if keys.any? { |key| LibRay.key_down?(key) }
        @key_down_initial_timers[timer_key].increase(frame_time)

        if @key_down_initial_timers[timer_key].done?
          @key_down_timers[timer_key].increase(frame_time)

          if @key_down_timers[timer_key].done?
            @key_down_timers[timer_key].reset
            return true
          end
        end
      elsif keys.any? { |key| LibRay.key_released?(key) }
        @key_down_initial_timers[timer_key].reset
      end

      false
    end
  end
end
