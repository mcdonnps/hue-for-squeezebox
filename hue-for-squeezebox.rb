#!/usr/bin/env ruby

require 'echowrap'
require 'hue'
require 'squeezer'

# Color mappings based off Newton's color wheel
# http://tomellard.com/wp/wp-content/uploads/2014/01/Newtons-colour-wheel.jpg
# (c, c-sharp, d, e-flat, e, f, f-sharp, g, a-flat, a, b-flat, b) 0 - 11
# array is xy color
colors = {
  0 => {:x => 0.15914, :y => 0.09869},
  1 => {:x => 0.22430, :y => 0.12514},
  2 => {:x => 0.31838, :y => 0.17666},
  3 => {:x => 0.42430, :y => 0.23873},
  4 => {:x => 0.56316, :y => 0.33393},
  5 => {:x => 0.46303, :y => 0.43574},
  6 => {:x => 0.41747, :y => 0.49176},
  7 => {:x => 0.36042, :y => 0.53709},
  8 => {:x => 0.31834, :y => 0.56770},
  9 => {:x => 0.27491, :y => 0.45559},
  10 => {:x => 0.23000, :y => 0.34380},
  11 => {:x => 0.20568, :y => 0.25731}
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
  
      # Return key for song 
      begin

        key = Echowrap.song_search(:artist => song[:artist], :title => song[:title], :bucket => 'audio_summary').first.audio_summary.key

        # Adjust hue based on key
        hue.lights.each do |light|
          light.set_state(:xy => [colors[key][:x], colors[key][:y]])
        end

      rescue
      end    

    end

  end

end
