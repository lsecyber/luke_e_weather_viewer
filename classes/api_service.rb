# frozen_string_literal: true

require 'net/http'

class ApiService
  attr_reader :data, :complete_url

  def initialize(url, params, fetch_data = true)
    uri = URI(url)
    uri.query = URI.encode_www_form params
    @complete_url = uri

    return unless fetch_data

    @data = get_data uri

  end

  private

  def get_data(uri)
    response = Net::HTTP.get(uri)
    json_parse_if_needed response
  end

  def json_parse_if_needed(item)
    begin
      JSON.parse(item)
    rescue JSON::ParserError
      item
    end
  end
end
