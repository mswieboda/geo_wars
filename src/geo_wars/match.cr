module GeoWars
  class Match
    delegate cursor_cell, to: @map
    delegate selected_unit, to: @map

    @map : Map
    @players : Array(Player)

    @turn_color : LibRay::Color
    @hud_info_color : LibRay::Color

    HUD_MARGIN = 8

    TURN_TEXT_PADDING = 4

    HUD_INFO_TEXT_PADDING     = 8
    HUD_INFO_BACKGROUND_COLOR = LibRay::Color.new(r: 0, g: 0, b: 0, a: 100)

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

      @hud_info_font_size = 14
      @hud_info_spacing = 4
      @hud_info_color = LibRay::WHITE
      @hud_info_measured = LibRay.measure_text_ex(
        sprite_font: @sprite_font,
        text: "Def 0",
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing
      )

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
      draw_hud_info
      draw_hud_turn
    end

    def draw_hud_info
      draw_hud_terrain_info
      draw_hud_unit_info
    end

    def draw_hud_terrain_info
      width = 128
      height = 96

      x = Game::SCREEN_WIDTH - width - HUD_MARGIN
      y = Game::SCREEN_HEIGHT - height - HUD_MARGIN

      LibRay.draw_rectangle(
        pos_x: x,
        pos_y: y,
        width: width,
        height: height,
        color: HUD_INFO_BACKGROUND_COLOR
      )

      # description
      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: cursor_cell.terrain.to_s,
        position: LibRay::Vector2.new(
          x: x + HUD_INFO_TEXT_PADDING,
          y: y + HUD_INFO_TEXT_PADDING,
        ),
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing,
        color: @hud_info_color
      )

      # defense
      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: "Def: #{cursor_cell.terrain.defense}",
        position: LibRay::Vector2.new(
          x: x + HUD_INFO_TEXT_PADDING,
          y: y + HUD_INFO_TEXT_PADDING + @hud_info_measured.y + HUD_INFO_TEXT_PADDING
        ),
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing,
        color: @hud_info_color
      )

      # moves
      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: "Moves: #{cursor_cell.terrain.moves}",
        position: LibRay::Vector2.new(
          x: x + HUD_INFO_TEXT_PADDING,
          y: y + HUD_INFO_TEXT_PADDING + (@hud_info_measured.y + HUD_INFO_TEXT_PADDING) * 2
        ),
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing,
        color: @hud_info_color
      )
    end

    def draw_hud_unit_info
      cursor_unit = cursor_cell.unit

      return unless cursor_unit

      cursor_unit = cursor_unit.as(Units::Unit)

      width = 128
      height = 96

      x = Game::SCREEN_WIDTH - width * 2 - HUD_MARGIN
      y = Game::SCREEN_HEIGHT - height - HUD_MARGIN

      LibRay.draw_rectangle(
        pos_x: x,
        pos_y: y,
        width: width,
        height: height,
        color: HUD_INFO_BACKGROUND_COLOR
      )

      # description
      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: cursor_unit.description.to_s,
        position: LibRay::Vector2.new(
          x: x + HUD_INFO_TEXT_PADDING,
          y: y + HUD_INFO_TEXT_PADDING,
        ),
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing,
        color: @hud_info_color
      )

      # moves
      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: "Moves: #{cursor_unit.max_movement}",
        position: LibRay::Vector2.new(
          x: x + HUD_INFO_TEXT_PADDING,
          y: y + HUD_INFO_TEXT_PADDING + @hud_info_measured.y + HUD_INFO_TEXT_PADDING
        ),
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing,
        color: @hud_info_color
      )

      # damage
      return unless selected_unit
      return if selected_unit.try { |u| u.player == cursor_unit.player }

      LibRay.draw_text_ex(
        sprite_font: @sprite_font,
        text: "Damage: #{selected_unit.try { |u| u.attack_preview_percentage(cursor_unit, cursor_cell) }}%",
        position: LibRay::Vector2.new(
          x: x + HUD_INFO_TEXT_PADDING,
          y: y + HUD_INFO_TEXT_PADDING + (@hud_info_measured.y + HUD_INFO_TEXT_PADDING) * 2
        ),
        font_size: @hud_info_font_size,
        spacing: @hud_info_spacing,
        color: @hud_info_color
      )
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
