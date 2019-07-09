module GeoWars
  class Unit
    getter x : Int32
    getter y : Int32
    getter? selected
    getter moves : Array(NamedTuple(x: Int32, y: Int32))

    SIZE_RATIO = 0.5

    SELECTED_BORDER_TIMER = 0.75
    SELECTED_BORDER_COLOR = LibRay::BLACK

    SELECTED_BORDER_SIZE_RATIO = 16

    MAX_MOVEMENT          = 3
    MOVEMENT_RADIUS_COLOR = LibRay::Color.new(r: 255, g: 255, b: 255, a: 85)

    def initialize(@x, @y)
      @selected = false
      @selected_border_timer = Timer.new(SELECTED_BORDER_TIMER)
      @moves = Array(NamedTuple(x: Int32, y: Int32)).new
      @moves = default_moves
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

      @moves.each do |move|
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

    def default_moves
      (-MAX_MOVEMENT..MAX_MOVEMENT).to_a.flat_map do |x|
        max = MAX_MOVEMENT - x.abs

        (-max..max).to_a.flat_map do |y|
          {x: x, y: y}
        end
      end
    end

    def move(x, y)
      @x = x
      @y = y
    end

    def select
      @selected = !@selected
    end

    def unselect
      @selected = false
    end

    def serialize
      "u:#{@x},#{@y}"
    end

    def self.deserialize(line)
      x, y = line.split(":").last.split(",").map(&.to_i)
      Unit.new(x, y)
    end
  end
end
