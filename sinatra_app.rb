# frozen_string_literal: true

require 'sinatra'
require 'net/http'
require 'json'
require 'date'
require 'time'
require 'down'
require 'fileutils'


def round_to_nearest_hour(t)
  rounded = Time.at((t.to_time.to_i / (60.0 * 60.0)).floor * (60 * 60))
  t.is_a?(DateTime) ? rounded.to_datetime : rounded
end



class LocationData
  attr_accessor :longitude, :latitude, :city, :state, :zip

  def initialize
    loc = Net::HTTP.get(URI('https://ipapi.co/json/'))
    data = JSON.parse(loc)
    @longitude = data['longitude']
    @latitude = data['latitude']
    @city = data['city']
    @state = data['region']
    @zip = data['postal']
  end
end

class WeatherData
  RAIN_ICON = 'rainy-outline'
  CLOUDY_ICON = 'cloudy-outline'
  PARTLY_SUNNY_ICON = 'partly-sunny-outline'
  SUNNY_ICON = 'sunny-outline'
  MOON_ICON = 'moon-outline'

  attr_reader :dates_w_data, :maxes, :mins, :day_icons, :today

  def initialize(longitude, latitude)
    api_data = get_weather_data(longitude, latitude)
    dates = api_data['daily']['time']
    maxes = api_data['daily']['temperature_2m_max']
    mins = api_data['daily']['temperature_2m_min']
    precipitations = api_data['daily']['precipitation_sum']
    cloudcover = hourly_cloudcover_to_avgs(api_data['hourly']['time'], api_data['hourly']['cloudcover'])
    @day_icons = precipitations.zip(cloudcover).map { |i| precipitation_cloudcover_to_icon(i[0], i[1]) }

    @maxes = maxes.map do |str|
      str.to_f.round
    end
    @mins = mins.map do |str|
      str.to_f.round
    end

    @dates_w_data = Hash[dates.zip(@maxes.zip(@mins, @day_icons))]

    puts "Dev: #{round_to_nearest_hour(DateTime.now).strftime('%Y-%m-%dT%H:%M')}"
    today_hour_index = api_data['hourly']['time'].find_index round_to_nearest_hour(DateTime.now).strftime('%Y-%m-%dT%H:%M')
    today_daily_data = @dates_w_data[DateTime.now.strftime('%Y-%m-%d')]
    puts "today_hour_index: #{today_hour_index}"
    today_precipitation = api_data['hourly']['precipitation'][today_hour_index]
    today_cloudcover = api_data['hourly']['cloudcover'][today_hour_index]
    @today = {
      icon: precipitation_cloudcover_to_icon(
        today_precipitation,
        today_cloudcover,
        DateTime.now.strftime('%Y-%m-%dT%H:%M'),
        api_data['daily']['sunrise'][0],
        api_data['daily']['sunset'][0]
      ),
      high: today_daily_data[0],
      low: today_daily_data[1],
      current: api_data['hourly']['temperature_2m'][today_hour_index].round.to_s
    }
  end


  private

  def get_weather_data(long, lat)
    uri = URI('https://api.open-meteo.com/v1/forecast')
    now_plus_seven_days = DateTime.now.to_date + 7
    params = {
      latitude: lat,
      longitude: long,
      daily: %w[temperature_2m_max temperature_2m_min uv_index_max precipitation_sum sunrise sunset],
      hourly: %w[cloudcover precipitation temperature_2m],
      temperature_unit: 'fahrenheit',
      windspeed_unit: 'mph',
      precipitation_unit: 'inch',
      timezone: 'auto',
      start_date: DateTime.now.to_date.strftime('%Y-%m-%d'),
      end_date: now_plus_seven_days.strftime('%Y-%m-%d')
    }

    uri.query = URI.encode_www_form params
    puts 'uri:', uri
    res = Net::HTTP.get(uri)
    JSON.parse res
  end

  def hourly_cloudcover_to_avgs(times, hourly_data)
    total_cloud_cover = 0
    count = 0
    averages = []

    times.each_with_index do |time, index|
      time = Time.parse(time)
      if time.hour >= 8 && time.hour < 18
        total_cloud_cover += hourly_data[index]
        count += 1
      end

      next unless (time.hour > 17 && index.positive? && count.positive?) || index == times.length - 1 && count.positive?

      averages.push(total_cloud_cover / count.to_f)
      total_cloud_cover = 0
      count = 0
    end

    averages
  end

  def precipitation_cloudcover_to_icon(precipitation, cloudcover, current_time = nil, sunrise_time = nil, sunset_time = nil)
    if !current_time.nil? && !sunrise_time.nil? && !sunset_time.nil? && \
       (Time.parse(current_time) < Time.parse(sunrise_time) \
       || Time.parse(current_time) > Time.parse(sunset_time))
      MOON_ICON
    elsif precipitation > 0.01
      RAIN_ICON
    elsif cloudcover >= 60
      CLOUDY_ICON
    elsif cloudcover >= 35
      PARTLY_SUNNY_ICON
    else
      SUNNY_ICON
    end
  end
end

class BarChart
  attr_accessor :image_url

  def initialize(maxes, mins, date_list)
    day_names = convert_date_list_to_names date_list
    @image_url = get_image(maxes, mins, day_names)
  end

  private

  def convert_date_list_to_names(date_list)
    date_list.map do |date_str|
      Date.parse(date_str).strftime('%a')
    end
  end

  def get_image(maxes, mins, day_names)
    uri = URI('https://image-charts.com/chart')
    params = {
      chan: '1200',
      chbr: '10',
      chco: '0096FF,DB564D',
      chd: "t:#{mins.join(',')}|#{maxes.join(',')}",
      chdl: 'Low|High',
      chds: '0,120',
      chm: 'N,000000,0,,10|N,000000,1,,10|N,000000,2,,10',
      chma: '0,0,10,10',
      chs: '999x400',
      cht: 'bvg',
      chxl: "0:|#{day_names.join('|')}",
      chxt: 'x,y'
      #chxs: '0,000000,0,0,_'
    }
    uri.query = URI.encode_www_form params
    puts uri

    uri
  end
end


get '/' do
  location_data = LocationData.new
  weather_info = WeatherData.new location_data.longitude, location_data.latitude
  image_data = BarChart.new(weather_info.maxes, weather_info.mins, weather_info.dates_w_data.keys)
  erb :index, locals: { data: weather_info, bar_graph_url: image_data.image_url }
end
