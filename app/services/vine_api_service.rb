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

    response = connection.get(my_team_url)

    log_error("VineApiService#my_team", response)

    response
  end

  def voucher_validation(voucher_short_code)
    voucher_validation_url = "#{@vine_api_url}/voucher-validation"

    response = connection.post(
      voucher_validation_url,
      { type: "voucher_code", value: voucher_short_code },
      'Content-Type': "application/json"
    )

    log_error("VineApiService#voucher_validation", response)

    response
  end

  def voucher_redemptions(voucher_id, voucher_set_id, amount)
    voucher_redemptions_url = "#{@vine_api_url}/voucher-redemptions"

    response = connection.post(
      voucher_redemptions_url,
      { voucher_id:, voucher_set_id:, amount: amount.to_i },
      'Content-Type': "application/json"
    )

    log_error("VineApiService#voucher_redemptions", response)

    response
  end

  private

  def connection
    jwt = jwt_generator.generate_token
    Faraday.new(
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
  end

  def log_error(prefix, response)
    return if response.success?

    Rails.logger.error "#{prefix} -- response_status: #{response.status}"
    Rails.logger.error "#{prefix} -- response: #{response.body}"
  end
end
