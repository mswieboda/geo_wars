module GeoWars
  class Game
    SCREEN_WIDTH  = 1280
    SCREEN_HEIGHT =  768

    DEBUG = false

    TARGET_FPS = 60
    DRAW_FPS   = DEBUG

    KEY_TILDE =  96
    KEY_TAB   = 258

    INPUT_ACCEPT = LibRay::KEY_ENTER
    INPUT_CANCEL = LibRay::KEY_BACKSPACE

    def initialize
      LibRay.init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "Geo")
      LibRay.set_target_fps(TARGET_FPS)

      @match = Match.new
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
      @match.update(frame_time)
    end

    def draw
      @match.draw
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
