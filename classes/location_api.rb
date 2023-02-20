# frozen_string_literal: true

require_relative 'api_service'

class LocationApi < ApiService

  attr_reader :longitude, :latitude, :city, :state, :zip

  def initialize(url = 'https://ipapi.co/json', query = {})
    super url, query
    @longitude = @data['longitude']
    @latitude = @data['latitude']
    @city = @data['city']
    @state = @data['region']
    @zip = @data['postal']
  end


end

