require "cray"
require "./geo_wars/*"

module GeoWars
  def self.run
    Game.new.run
  end
end

GeoWars.run
