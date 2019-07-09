module GeoWars
  class Cursor
    SIZE_RATIO              =  0.9
    SIZE_RATIO_SHRINK       =  0.8
    SIZE_RATIO_SHRINK_TIMER = 0.75

    KEY_DOWN_INITIAL_TIMER =   0.5
    KEY_DOWN_TIMER         = 0.125

    BORDER_WIDTH = 6

    CURSOR_COLOR = LibRay::BLACK

    property x
    property y

    @key_down_initial_timers : Hash(Symbol, Timer)
    @key_down_timers : Hash(Symbol, Timer)

    def initialize(@x : Int32, @y : Int32)
      @key_down_initial_timers = Hash(Symbol, Timer).new
      @key_down_timers = Hash(Symbol, Timer).new

      [:up, :left, :down, :right].each do |key|
        @key_down_initial_timers[key] = Timer.new(KEY_DOWN_TIMER)
        @key_down_timers[key] = Timer.new(KEY_DOWN_TIMER)
      end

      @size_ratio = SIZE_RATIO
      @size_ratio_shrink_timer = Timer.new(SIZE_RATIO_SHRINK_TIMER)
    end

    def update(cell_width, cell_height, frame_time)
      @y -= 1 if LibRay.key_pressed?(LibRay::KEY_W)
      @x -= 1 if LibRay.key_pressed?(LibRay::KEY_A)
      @y += 1 if LibRay.key_pressed?(LibRay::KEY_S)
      @x += 1 if LibRay.key_pressed?(LibRay::KEY_D)

      @y -= 1 if keys_held?(frame_time, [LibRay::KEY_W, LibRay::KEY_UP], :up)
      @x -= 1 if keys_held?(frame_time, [LibRay::KEY_A, LibRay::KEY_LEFT], :left)
      @y += 1 if keys_held?(frame_time, [LibRay::KEY_S, LibRay::KEY_DOWN], :down)
      @x += 1 if keys_held?(frame_time, [LibRay::KEY_D, LibRay::KEY_RIGHT], :right)

      @x = @x.clamp(0, cell_width - 1)
      @y = @y.clamp(0, cell_height - 1)

      @size_ratio_shrink_timer.increase(frame_time)
      @size_ratio = @size_ratio_shrink_timer.percentage > 0.5 ? SIZE_RATIO_SHRINK : SIZE_RATIO
      @size_ratio_shrink_timer.reset if @size_ratio_shrink_timer.done?
    end

    def draw(viewport)
      width = viewport.cell_size
      height = viewport.cell_size

      return unless viewport.viewable_cell?(@x, @y, width, height)

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      BORDER_WIDTH.times do |num|
        LibRay.draw_rectangle_lines(
          pos_x: x + (num + width - width * @size_ratio) / 2,
          pos_y: y + (num + height - height * @size_ratio) / 2,
          width: (width - num) * @size_ratio,
          height: (height - num) * @size_ratio,
          color: CURSOR_COLOR
        )
      end
    end

    def keys_held?(frame_time, keys, timer_key)
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
