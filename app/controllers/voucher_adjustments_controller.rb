# frozen_string_literal: true

class VoucherAdjustmentsController < BaseController
  before_action :set_order

  def create
    if add_voucher
      VoucherAdjustmentsService.calculate(@order)

      render_voucher_section
    elsif @order.errors.present?
      render_error
    end
  end

  def destroy
    @order.voucher_adjustments.find_by(id: params[:id])&.destroy

    render_voucher_section
  end

  private

  def set_order
    @order = current_order
  end

  def add_voucher
    if params[:voucher_code].blank?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.voucher_not_found'))
      return false
    end

    voucher = Voucher.find_by(code: params[:voucher_code], enterprise: @order.distributor)

    if voucher.nil?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.voucher_not_found'))
      return false
    end

    adjustment = voucher.create_adjustment(voucher.code, @order)

    if !adjustment.valid?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.add_voucher_error'))
      adjustment.errors.each { |error| @order.errors.import(error) }
      return false
    end

    true
  end

  def render_voucher_section
    render cable_ready: cable_car.replace(
      selector: "#voucher-section",
      html: render_to_string(
        partial: "split_checkout/voucher_section",
        locals: { order: @order,voucher_adjustment: @order.voucher_adjustments.first }
      )
    )
  end

  def render_error
    flash.now[:error] = @order.errors.full_messages.to_sentence

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash }))
  end
end
