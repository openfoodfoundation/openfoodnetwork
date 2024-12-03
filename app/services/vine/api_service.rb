# frozen_string_literal: true

require "faraday"

module Vine
  class ApiService
    attr_reader :api_key, :jwt_generator

    def initialize(api_key:, jwt_generator:)
      @vine_api_url = ENV.fetch("VINE_API_URL")
      @api_key = api_key
      @jwt_generator = jwt_generator
    end

    def my_team
      my_team_url = "#{@vine_api_url}/my-team"

      call_with_logging do
        connection.get(my_team_url)
      end
    end

    def voucher_validation(voucher_short_code)
      voucher_validation_url = "#{@vine_api_url}/voucher-validation"

      call_with_logging do
        connection.post(
          voucher_validation_url,
          { type: "voucher_code", value: voucher_short_code },
          'Content-Type': "application/json"
        )
      end
    end

    def voucher_redemptions(voucher_id, voucher_set_id, amount)
      voucher_redemptions_url = "#{@vine_api_url}/voucher-redemptions"

      call_with_logging do
        connection.post(
          voucher_redemptions_url,
          { voucher_id:, voucher_set_id:, amount: amount.to_i },
          'Content-Type': "application/json"
        )
      end
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
        f.use Faraday::Response::RaiseError
      end
    end

    def call_with_logging
      yield
    rescue Faraday::ClientError, Faraday::ServerError => e
      # caller_location(2,1) gets us the second entry in the stacktrace,
      # ie the method where `call_with_logging` is called from
      log_error("#{self.class}##{caller_locations(2, 1)[0].label}", e.response)

      # Re raise the same exception
      raise
    end

    def log_error(prefix, response)
      Rails.logger.error "#{prefix} -- response_status: #{response[:status]}"
      Rails.logger.error "#{prefix} -- response: #{response[:body]}"
    end
  end
end
