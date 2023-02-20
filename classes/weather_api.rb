# frozen_string_literal: true

require_relative 'api_service'
require 'date'
require 'time'

class WeatherApi < ApiService
  RAIN_ICON = 'rainy-outline'
  CLOUDY_ICON = 'cloudy-outline'
  PARTLY_SUNNY_ICON = 'partly-sunny-outline'
  SUNNY_ICON = 'sunny-outline'
  MOON_ICON = 'moon-outline'

  attr_reader :highs, :lows, :dates_w_data, :today



  def initialize(longitude, latitude)

    url, params = generate_url_and_params(longitude, latitude)
    super(url, params)
    @highs = get_highs @data
    @lows = get_lows @data

    data_hourly = @data['hourly']
    data_daily = @data['daily']

    hourly_times = data_hourly['time']
    cloudcover_hourly = data_hourly['cloudcover']
    cloudcover_daily = hourly_data_to_daily(hourly_times, cloudcover_hourly, 8, 18)
    precipitation_max_daily = data_daily['precipitation_sum']
    @day_icons = precipitation_max_daily.zip(cloudcover_daily).map { |i| find_weather_icon(i[0], i[1]) }

    @dates_w_data = data_daily['time'].zip(@highs, @lows, @day_icons).map do |date, max, min, icon|
      [date.to_sym, { high: max, low: min, icon: icon }]
    end.to_h


    now_formatted_with_hour = DateTime.now.strftime('%Y-%m-%dT%H:%M')
    now_hour_index = hourly_times.find_index round_to_nearest_hour(DateTime.now).strftime('%Y-%m-%dT%H:%M')
    now_date_only = DateTime.now.strftime('%Y-%m-%d')

    today_precipitation = data_hourly['precipitation'][now_hour_index]
    today_cloudcover = data_hourly['cloudcover'][now_hour_index]
    today_daily_data = @dates_w_data[now_date_only.to_sym]
    puts 'dev today_daily_data:'
    puts @dates_w_data
    puts now_date_only
    puts ''
    today_sunrise = data_daily['sunrise'][0]
    today_sunset = data_daily['sunset'][0]
    temp_now = data_hourly['temperature_2m'][now_hour_index].round.to_s

    @today = {
      icon: find_weather_icon(
        today_precipitation,
        today_cloudcover,
        now_formatted_with_hour,
        today_sunrise,
        today_sunset
      ),
      high: today_daily_data[:high],
      low: today_daily_data[:low],
      current: temp_now
    }
  end

  private

  def generate_url_and_params(long, lat)
    url = 'https://api.open-meteo.com/v1/forecast'
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

    return url, params
  end
  
  def get_highs api_data
    api_data['daily']['temperature_2m_max'].map do |str|
      str.to_f.round
    end
  end

  def get_lows api_data
    api_data['daily']['temperature_2m_min'].map do |str|
      str.to_f.round
    end
  end

  def precipitations api_data
    api_data['daily']['precipitation_sum'].map(&:to_f)
  end

  def hourly_data_to_daily(times_array, hourly_data, min_hour = 0, max_hour = 23)
    daily_total = 0
    count = 0
    averages = []

    times_array.each_with_index do |time, index|
      time = Time.parse(time)
      if time.hour >= min_hour && time.hour < max_hour
        daily_total += hourly_data[index]
        count += 1
      end

      next unless (time.hour >= max_hour && index.positive? && count.positive?) || index == times_array.length - 1 && count.positive?

      averages.push(daily_total / count.to_f)
      daily_total = 0
      count = 0
    end

    averages
  end

  def find_weather_icon(precipitation, cloudcover, current_time = nil, sunrise_time = nil, sunset_time = nil)
    check_for_night = !current_time.nil? && !sunrise_time.nil? && !sunset_time.nil?
    is_night = false
    if check_for_night
      current = Time.parse(current_time)
      sunrise = Time.parse(sunrise_time)
      sunset = Time.parse(sunset_time)
      is_night = (current < sunrise || current > sunset)
    end

    if is_night
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

  def round_to_nearest_hour(t)
    rounded = Time.at((t.to_time.to_i / (60.0 * 60.0)).floor * (60 * 60))
    t.is_a?(DateTime) ? rounded.to_datetime : rounded
  end
end


=begin
class WeatherData
  RAIN_ICON = 'rainy-outline'
  CLOUDY_ICON = 'cloudy-outline'
  PARTLY_SUNNY_ICON = 'partly-sunny-outline'
  SUNNY_ICON = 'sunny-outline'
  MOON_ICON = 'moon-outline'

  attr_reader :dates_w_data, :maxes, :mins, :day_icons, :today

  def initialize(longitude, latitude)
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
=end
