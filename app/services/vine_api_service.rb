# frozen_string_literal: true

require "faraday"

class VineApiService
  attr_reader :api_key, :jwt_generator

  def initialize(api_key:, jwt_generator:)
    @vine_api_url = ENV.fetch("VINE_API_URL")
    @api_key = api_key
    @jwt_generator = jwt_generator
  end

  def my_team
    my_team_url = "#{@vine_api_url}/my-team"

    jwt = jwt_generator.generate_token
    connection = Faraday.new(
      request: { timeout: 30 },
      headers: {
        'X-Authorization': "JWT #{jwt}",
        Accept: "application/json"
      }
    ) do |f|
      f.request :json
      f.response :json
      f.request :authorization, 'Bearer', api_key
    end

    response = connection.get(my_team_url)

    if !response.success?
      Rails.logger.error "VineApiService#my_team -- response_status: #{response.status}"
      Rails.logger.error "VineApiService#my_team -- response: #{response.body}"
    end

    response
  end
end
