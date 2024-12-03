# frozen_string_literal: true

class VineVoucherRedeemerService
  attr_reader :order, :errors

  def initialize(order: )
    @order = order
    @errors = {}
  end

  def call
    # Do nothing if we don't have a vine voucher added to the order
    voucher_adjustment = order.voucher_adjustments.first
    @voucher = voucher_adjustment&.originator

    return true if voucher_adjustment.nil? || !@voucher.vine?

    if vine_settings.nil?
      errors[:vine_settings] = I18n.t("vine_voucher_redeemer_service.errors.vine_settings")
      return false
    end

    response = call_vine_api

    if !response.success?
      handle_errors(response)
      return false
    end

    voucher_adjustment.close

    true
  rescue Faraday::Error => e
    Rails.logger.error e.inspect
    Bugsnag.notify(e)

    errors[:vine_api] = I18n.t("vine_voucher_validator_service.errors.vine_api")
    false
  end

  private

  def vine_settings
    ConnectedApps::Vine.find_by(enterprise: order.distributor)&.data
  end

  def call_vine_api
    jwt_service = VineJwtService.new(secret: vine_settings["secret"])
    vine_api = VineApiService.new(api_key: vine_settings["api_key"], jwt_generator: jwt_service)

    # Voucher amount is stored in dollars, VINE expect cents
    vine_api.voucher_redemptions(
      @voucher.external_voucher_id, @voucher.external_voucher_set_id, (@voucher.amount * 100)
    )
  end

  def handle_errors(response)
    if response.status == 400
      errors[:redeeming_failed] = I18n.t("vine_voucher_redeemer_service.errors.redeeming_failed")
    else
      errors[:vine_api] = I18n.t("vine_voucher_redeemer_service.errors.vine_api")
    end
  end
end
