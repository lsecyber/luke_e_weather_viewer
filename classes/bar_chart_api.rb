# frozen_string_literal: true

require_relative 'api_service'
require 'date'

class BarChartApi < ApiService
  attr_reader :image_url

  def initialize(highs, lows, date_list)
    url, params = create_url(highs, lows, convert_date_list_to_day_of_week_list(date_list))
    super(url, params, false)
    @image_url = @complete_url
  end

  private

  def convert_date_list_to_day_of_week_list(date_list)
    date_list.map do |date_str|
      Date.parse(date_str.to_s).strftime('%a')
    end
  end

  def create_url(highs, lows, day_names)
    uri = URI('https://image-charts.com/chart')
    params = {
      chan: '3600',
      chbr: '10',
      chco: '0096FF,DB564D',
      chd: "t:#{lows.join(',')}|#{highs.join(',')}",
      chdl: 'Low|High',
      chds: '0,120',
      chm: 'N,000000,0,,10|N,000000,1,,10|N,000000,2,,10',
      chma: '0,0,10,10',
      chs: '999x400',
      cht: 'bvg',
      chxl: "0:|#{day_names.join('|')}",
      chxt: 'x,y'
    }
    [uri, params]
  end
end
