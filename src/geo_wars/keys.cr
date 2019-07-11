module GeoWars
  class Keys
    ACCEPT = LibRay::KEY_ENTER
    CANCEL = LibRay::KEY_BACKSPACE

    TILDE =  96
    TAB   = 258

    def self.held?(frame_time, key : Int32, initial_timer, hold_timer)
      held?(frame_time, [key], initial_timer, hold_timer)
    end

    def self.held?(frame_time, keys : Array(Int32), initial_timer, hold_timer)
      if keys.any? { |key| down?(key) }
        initial_timer.increase(frame_time)

        if initial_timer.done?
          hold_timer.increase(frame_time)

          if hold_timer.done?
            hold_timer.reset
            return true
          end
        end
      elsif keys.any? { |key| released?(key) }
        hold_timer.reset
        initial_timer.reset
      end

      false
    end

    def self.pressed_or_held?(frame_time, key : Int32, initial_timer, hold_timer)
      return true if pressed?(key)

      held?(frame_time, key, initial_timer, hold_timer)
    end

    def self.pressed_or_held?(frame_time, keys : Array(Int32), initial_timer, hold_timer)
      return true if pressed?(keys)

      held?(frame_time, keys, initial_timer, hold_timer)
    end

    def self.pressed?(key : Int32)
      LibRay.key_pressed?(key)
    end

    def self.pressed?(keys : Array(Int32))
      keys.any? { |key| pressed?(key) }
    end

    def self.down?(key : Int32)
      LibRay.key_down?(key)
    end

    def self.down?(key : Array(Int32))
      keys.any? { |key| down?(key) }
    end

    def self.released?(key : Int32)
      LibRay.key_released?(key)
    end

    def self.released?(key : Array(Int32))
      keys.any? { |key| released?(key) }
    end

    def self.up?(key : Int32)
      LibRay.key_up?(key)
    end

    def self.up?(key : Array(Int32))
      keys.any? { |key| up?(key) }
    end

    def self.puts_pressed
      key = LibRay.get_key_pressed
      puts key unless key == -1
    end
  end
end
