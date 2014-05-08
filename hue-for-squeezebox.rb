#!/usr/bin/env ruby

require 'echowrap'
require 'hue'
require 'squeezer'

# Color mappings based off http://wagneric.com/audiocolors.html
# (c, c-sharp, d, e-flat, e, f, f-sharp, g, a-flat, a, b-flat, b) 0 - 11
colors = {
  0 => {:hue => 20206, :bri => 254},
  1 => {:hue => 32221, :bri => 254},
  2 => {:hue => 38410, :bri => 254},
  3 => {:hue => 43872, :bri => 254},
  4 => {:hue => 46966, :bri => 222},
  5 => {:hue => 49697, :bri => 120},
  6 => {:hue => 0, :bri => 173},
  7 => {:hue => 0, :bri => 254},
  8 => {:hue => 0, :bri => 254},
  9 => {:hue => 4369, :bri => 254},
  10 => {:hue => 10194, :bri => 254},
  11 => {:hue => 15291, :bri => 254}
}

# Squeeze config
Squeezer.configure do |config|
  config.server = "127.0.0.1"
  config.port = 9090
end

# Echonest config
Echowrap.configure do |config|
  config.api_key = 'your api key'
  config.consumer_key = 'your consumer key'
  config.shared_secret = 'your shared secret'
end

# Create clients
hue = Hue::Client.new
squeeze = Squeezer::Client.new

# Initialize song
song = true

# Schedule run every second
while true do

  # Sleep 1 second
  sleep 1

  # Don't do anything if Squeezebox not playing
  if squeeze.players.first.playing?
  
    # Prevent hitting Echonest every second
    unless song == Squeezer::Models::Model.extract_records(Squeezer::Connection.exec("#{squeeze.players.first.id} status -")).first

      song = Squeezer::Models::Model.extract_records(Squeezer::Connection.exec("#{squeeze.players.first.id} status -")).first
  
      # Just in case the song doesn't exist in Echonest
      begin

        # Return metadata for song, pull out key and mode
        metadata = Echowrap.song_search(:artist => song[:artist], :title => song[:title], :bucket => 'audio_summary').first.audio_summary
        key = metadata.key
        mode = metadata.mode

        # Adjust saturation based on mode (major keys are lower saturation, minor keys are higher)
        saturation = mode.zero? ? 128 : 254

        # Adjust hue based on key
        hue.lights.each do |light|
          light.set_state(:hue => colors[key][:hue], :brightness => colors[key][:bri], :saturation => saturation, :color_mode => "hs")
        end

      rescue
      end    

    end

  end

end
