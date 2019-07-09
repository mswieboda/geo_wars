module GeoWars
  class Game
    SCREEN_WIDTH  = 1280
    SCREEN_HEIGHT =  768

    DEBUG = false

    TARGET_FPS = 60
    DRAW_FPS   = DEBUG

    def initialize
      LibRay.init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "Geo")
      LibRay.set_target_fps(TARGET_FPS)

      @map = Map.new(
        cells_x: 20,
        cells_y: 20
      )
    end

    def run
      while !LibRay.window_should_close?
        frame_time = LibRay.get_frame_time
        update(frame_time)
        draw_init
      end

      close
    end

    def update(frame_time)
      @map.update(frame_time)
    end

    def draw
      @map.draw
    end

    def draw_init
      LibRay.begin_drawing
      LibRay.clear_background LibRay::BLACK

      draw

      LibRay.draw_fps(0, 0) if DRAW_FPS
      LibRay.end_drawing
    end

    def close
      LibRay.close_window
    end
  end
end
