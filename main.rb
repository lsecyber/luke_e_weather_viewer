# frozen_string_literal: true

require 'sinatra'
require 'net/http'
require 'json'
require 'date'
require 'time'
require 'fileutils'
require_relative 'classes/location_api'
require_relative 'classes/weather_api'
require_relative 'classes/bar_chart_api'

def round_to_nearest_hour(t)
  rounded = Time.at((t.to_time.to_i / (60.0 * 60.0)).floor * (60 * 60))
  t.is_a?(DateTime) ? rounded.to_datetime : rounded
end

get '/' do
  location_data = LocationApi.new
  weather_info = WeatherApi.new(location_data.longitude, location_data.latitude)
  image_data = BarChartApi.new(weather_info.highs, weather_info.lows, weather_info.dates_w_data.keys)
  erb :index, locals: { data: weather_info, bar_graph_url: image_data.image_url }
end

get '/favicon.ico' do
  puts settings.public_dir
  send_file File.join(settings.public_dir, 'favicon.ico')
end
