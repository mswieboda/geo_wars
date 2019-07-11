module GeoWars
  class Timer
    getter time : Float32
    getter length : Float64 | Float32 | Int32
    getter? started

    def initialize(@length : Float64 | Float32 | Int32)
      @started = false
      @time = 0_f32
    end

    def start
      @started = true
    end

    def done?
      started? && @time >= @length
    end

    def reset
      @started = false
      @time = 0_f32
    end

    def restart
      reset
      start
    end

    def increase(delta_t : Float32)
      start unless started?
      @time += delta_t
    end

    def percentage
      @time / @length
    end

    def toggle?
      percentage > 0.5
    end
  end
end
