module GeoWars
  class Match
    @map : Map
    @players : Array(Player)

    @turn_color : LibRay::Color

    HUD_MARGIN = 8

    TURN_TEXT_PADDING = 4

    NEXT_TURN_KEY_HOLD_INITIAL_TIMER = 0.5
    NEXT_TURN_KEY_HOLD_TIMER         =   1

    def initialize
      players = [] of Player
      players << Player.new(color: LibRay::RED)
      players << Player.new(color: LibRay::DARKBLUE)

      map = Map.new(
        cells_x: 20,
        cells_y: 20,
        players: players
      )

      initialize(map, players)
    end

    def initialize(@map, @players)
      @turn_player_index = 0
      @turn = 0

      @sprite_font = LibRay.get_default_font

      @turn_font_size = 18
      @turn_spacing = 4
      @turn_text = "Turn"
      @next_turn_text = "Next ?"
      @turn_color = LibRay::WHITE
      @turn_measured = LibRay::Vector2.new
      @turn_position = LibRay::Vector2.new

      new_turn

      @next_turn_key_hold_initial_timer = Timer.new(NEXT_TURN_KEY_HOLD_INITIAL_TIMER)
      @next_turn_key_hold_timer = Timer.new(NEXT_TURN_KEY_HOLD_TIMER)
    end

    def update(frame_time)
      if Keys.held?(frame_time, Keys::CANCEL, @next_turn_key_hold_initial_timer, @next_turn_key_hold_timer)
        @next_turn_key_hold_timer.reset
        @next_turn_key_hold_initial_timer.reset

        new_index = @turn_player_index + 1
        @turn_player_index = new_index >= @players.size ? 0 : new_index

        @map.new_player_turn

        new_turn if @turn_player_index == 0

        @map.turn_player = turn_player
      end

      @map.update(frame_time)
    end

    def draw
      @map.draw

      draw_hud
    end

    def draw_hud
      draw_hud_turn
    end

    def draw_hud_turn
      LibRay.draw_rectangle(
        pos_x: @turn_position.x - TURN_TEXT_PADDING,
        pos_y: @turn_position.y - TURN_TEXT_PADDING,
        width: @turn_measured.x + TURN_TEXT_PADDING * 2,
        height: @turn_measured.y + TURN_TEXT_PADDING * 2,
        color: turn_player.color
      )

      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: @turn_text,
        position: @turn_position,
        font_size: @turn_font_size,
        spacing: @turn_spacing,
        color: @turn_color
      )

      # progress bar for holding cancel to confirm ending turn
      if @next_turn_key_hold_timer.started?
        max_width = @turn_measured.x + TURN_TEXT_PADDING * 2

        width = @next_turn_key_hold_timer.percentage * max_width

        LibRay.draw_rectangle(
          pos_x: @turn_position.x - TURN_TEXT_PADDING,
          pos_y: @turn_position.y + @turn_measured.y + TURN_TEXT_PADDING * 2,
          width: width,
          height: 8,
          color: turn_player.color
        )
      end
    end

    def turn_player
      @players[@turn_player_index]
    end

    def new_turn
      @turn += 1
      @turn_text = "Turn #{@turn}"
      @turn_measured = LibRay.measure_text_ex(
        sprite_font: @sprite_font,
        text: @turn_text,
        font_size: @turn_font_size,
        spacing: @turn_spacing
      )
      @turn_position = LibRay::Vector2.new(
        x: Game::SCREEN_WIDTH - HUD_MARGIN - TURN_TEXT_PADDING - @turn_measured.x,
        y: HUD_MARGIN + TURN_TEXT_PADDING
      )
    end
  end
end
