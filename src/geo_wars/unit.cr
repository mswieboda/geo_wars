module GeoWars
  class Unit
    getter x : Int32
    getter y : Int32
    getter? selected

    SIZE_RATIO = 0.5

    SELECTED_BORDER_TIMER = 0.75
    SELECTED_BORDER_COLOR = LibRay::BLACK

    SELECTED_BORDER_SIZE_RATIO = 16

    def initialize(@x, @y)
      @selected = false
      @selected_border_timer = Timer.new(SELECTED_BORDER_TIMER)
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

      x = viewport.real_x(@x)
      y = viewport.real_y(@y)

      LibRay.draw_rectangle(
        pos_x: x + (viewport.cell_size - width) / 2,
        pos_y: y + (viewport.cell_size - height) / 2,
        width: width,
        height: height,
        color: color
      )

      if selected? && @selected_border_timer.toggle?
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

    def select
      @selected = !@selected
    end

    def unselect
      @selected = false
    end
  end
end
