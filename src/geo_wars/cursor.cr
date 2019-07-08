module GeoWars
  class Cursor
    SIZE_RATIO = 0.9

    KEY_DOWN_INITIAL_TIME = 0.25
    KEY_DOWN_TIME         =  0.1

    property x
    property y

    @key_down_initial_timers : Hash(Symbol, Timer)
    @key_down_timers : Hash(Symbol, Timer)

    def initialize(@x : Int32, @y : Int32)
      @key_down_initial_timers = Hash(Symbol, Timer).new
      @key_down_timers = Hash(Symbol, Timer).new

      [:up, :left, :down, :right].each do |key|
        @key_down_initial_timers[key] = Timer.new(KEY_DOWN_TIME)
        @key_down_timers[key] = Timer.new(KEY_DOWN_TIME)
      end
    end

    def update(cell_width, cell_height, frame_time)
      if LibRay.key_pressed?(LibRay::KEY_W)
        @y -= 1
      elsif LibRay.key_pressed?(LibRay::KEY_A)
        @x -= 1
      elsif LibRay.key_pressed?(LibRay::KEY_S)
        @y += 1
      elsif LibRay.key_pressed?(LibRay::KEY_D)
        @x += 1
      end

      if keys_held?(frame_time, [LibRay::KEY_W, LibRay::KEY_UP], :up)
        @y -= 1
      elsif keys_held?(frame_time, [LibRay::KEY_A, LibRay::KEY_LEFT], :left)
        @x -= 1
      elsif keys_held?(frame_time, [LibRay::KEY_S, LibRay::KEY_DOWN], :down)
        @y += 1
      elsif keys_held?(frame_time, [LibRay::KEY_D, LibRay::KEY_RIGHT], :right)
        @x += 1
      end

      @x = @x.clamp(0, cell_width - 1)
      @y = @y.clamp(0, cell_height - 1)
    end

    def draw(size)
      # border
      LibRay.draw_rectangle_lines(
        pos_x: @x * size + (size - size * SIZE_RATIO) / 2,
        pos_y: @y * size + (size - size * SIZE_RATIO) / 2,
        width: size * SIZE_RATIO,
        height: size * SIZE_RATIO,
        color: LibRay::BLACK
      )
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
