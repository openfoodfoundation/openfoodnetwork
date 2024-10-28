# frozen_string_literal: true

module Vine
  class VoucherValidatorService
    attr_reader :voucher_code, :errors

    def initialize(voucher_code:, enterprise:)
      @voucher_code = voucher_code
      @enterprise = enterprise
      @errors = {}
    end

    def validate
      if vine_settings.nil?
        errors[:vine_settings] = I18n.t("vine_voucher_validator_service.errors.vine_settings")
        return nil
      end

      response = call_vine_api

      if !response.success?
        handle_errors(response)
        return nil
      end

      save_voucher(response)
    rescue Faraday::Error => e
      Rails.logger.error e.inspect
      Bugsnag.notify(e)

      # TODO do we need a more specific error ?
      errors[:vine_api] = I18n.t("vine_voucher_validator_service.errors.vine_api")
      nil
    end

    private

    def vine_settings
      ConnectedApps::Vine.find_by(enterprise: @enterprise)&.data
    end

    def call_vine_api
      # Check voucher is valid
      jwt_service = Vine::JwtService.new(secret: vine_settings["secret"])
      vine_api = Vine::ApiService.new(api_key: vine_settings["api_key"], jwt_generator: jwt_service)

      vine_api.voucher_validation(voucher_code)
    end

    def handle_errors(response)
      if response.status == 400
        errors[:invalid_voucher] = I18n.t("vine_voucher_validator_service.errors.invalid_voucher")
      elsif response.status == 404
        errors[:not_found_voucher] =
          I18n.t("vine_voucher_validator_service.errors.not_found_voucher")
      else
        errors[:vine_api] = I18n.t("vine_voucher_validator_service.errors.vine_api")
      end
    end

    def save_voucher(response)
      voucher_data = response.body["data"]

      # Check if voucher already exist
      voucher = Voucher.vine.find_by(code: voucher_code, enterprise: @enterprise)

      amount = voucher_data["voucher_value_remaining"].to_f / 100
      if voucher.present?
        voucher.update(amount: )
      else
        voucher = Vouchers::FlatRate.create(
          enterprise: @enterprise,
          code: voucher_data["voucher_short_code"],
          amount:,
          external_voucher_id: voucher_data["id"],
          external_voucher_set_id: voucher_data["voucher_set_id"],
          voucher_type: "VINE"
        )
      end

      voucher
    end
  end
end
