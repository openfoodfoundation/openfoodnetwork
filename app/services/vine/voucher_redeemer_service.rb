# frozen_string_literal: true

module Vine
  class VoucherRedeemerService
    attr_reader :order, :errors

    def initialize(order: )
      @order = order
      @errors = {}
    end

    def redeem
      # Do nothing if we don't have a vine voucher added to the order
      @voucher_adjustment = order.voucher_adjustments.first
      @voucher = @voucher_adjustment&.originator

      return true if @voucher_adjustment.nil? || !@voucher.is_a?(Vouchers::Vine)

      return false if vine_settings.nil?

      call_vine_api

      @voucher_adjustment.close

      true
    rescue Faraday::ClientError => e
      handle_errors(e.response)
      false
    rescue Faraday::Error => e
      Rails.logger.error e.inspect
      Bugsnag.notify(e)

      errors[:vine_api] = I18n.t("vine_voucher_validator_service.errors.vine_api")
      false
    end

    private

    def vine_settings
      @vine_settings ||= ConnectedApps::Vine.find_by(enterprise: order.distributor)&.data
    end

    def call_vine_api
      jwt_service = Vine::JwtService.new(secret: vine_settings["secret"])
      vine_api = Vine::ApiService.new(api_key: vine_settings["api_key"], jwt_generator: jwt_service)

      # Voucher adjustment amount is stored in dollars and negative, VINE expect cents
      amount = -1 * @voucher_adjustment.amount * 100
      vine_api.voucher_redemptions(
        @voucher.external_voucher_id, @voucher.external_voucher_set_id, amount
      )
    end

    def handle_errors(response)
      if response[:status] == 400
        errors[:redeeming_failed] = I18n.t("vine_voucher_redeemer_service.errors.redeeming_failed")
      else
        errors[:vine_api] = I18n.t("vine_voucher_redeemer_service.errors.vine_api")
      end
    end
  end
end
