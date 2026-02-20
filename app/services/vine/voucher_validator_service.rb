# frozen_string_literal: true

module Vine
  class VoucherValidatorService
    VINE_ERRORS = {
      # https://github.com/openfoodfoundation/vine/blob/main/app/Enums/ApiResponse.php
      "This voucher has expired." => :expired,
    }.freeze

    attr_reader :voucher_code, :errors

    def initialize(voucher_code:, enterprise:)
      @voucher_code = voucher_code
      @enterprise = enterprise
      @errors = {}
    end

    def validate
      return nil if vine_settings.nil?

      response = call_vine_api

      save_voucher(response)
    rescue Faraday::ClientError => e
      handle_errors(e.response)
      nil
    rescue Faraday::Error => e
      Rails.logger.error e.inspect
      Bugsnag.notify(e)

      errors[:vine_api] = I18n.t("vine_voucher_validator_service.errors.vine_api")
      nil
    end

    private

    def vine_settings
      @vine_settings ||= ConnectedApps::Vine.find_by(enterprise: @enterprise)&.data
    end

    def call_vine_api
      # Check voucher is valid
      jwt_service = Vine::JwtService.new(secret: vine_settings["secret"])
      vine_api = Vine::ApiService.new(api_key: vine_settings["api_key"], jwt_generator: jwt_service)

      vine_api.voucher_validation(voucher_code)
    end

    def handle_errors(response)
      if [400, 409].include?(response[:status])
        message = response[:body] && JSON.parse(response[:body]).dig("meta", "message")
        key = VINE_ERRORS.fetch(message, :invalid_voucher)
        errors[:invalid_voucher] = I18n.t("vine_voucher_validator_service.errors.#{key}")
      elsif response[:status] == 404
        errors[:not_found_voucher] =
          I18n.t("vine_voucher_validator_service.errors.not_found_voucher")
      else
        errors[:vine_api] = I18n.t("vine_voucher_validator_service.errors.vine_api")
      end
    end

    def save_voucher(response)
      voucher_data = response.body["data"]

      # Check if voucher already exist
      voucher = Vouchers::Vine.find_or_initialize_by(
        code: voucher_code,
        enterprise: @enterprise,
        external_voucher_id: voucher_data["id"],
        external_voucher_set_id: voucher_data["voucher_set_id"]
      )
      voucher.amount = voucher_data["voucher_value_remaining"].to_f / 100
      voucher.save

      voucher
    end
  end
end
