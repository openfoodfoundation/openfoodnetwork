# frozen_string_literal: true

class VoucherAdjustmentsController < BaseController
  before_action :set_order

  def create
    if add_voucher
      update_payment_section
    elsif @order.errors.present?
      render_error
    end
  end

  def destroy
    @order.voucher_adjustments.find_by(id: params[:id])&.destroy

    # Update order to make sure we display the appropriate payment method
    @order.update_totals_and_states

    update_payment_section
  end

  private

  def set_order
    @order = current_order
  end

  def add_voucher
    if voucher_params[:voucher_code].blank?
      @order.errors.add(:voucher_code, I18n.t('split_checkout.errors.voucher_not_found'))
      return false
    end

    voucher = Voucher.find_by(code: voucher_params[:voucher_code], enterprise: @order.distributor)

    if voucher.nil?
      @order.errors.add(:voucher_code, I18n.t('split_checkout.errors.voucher_not_found'))
      return false
    end

    adjustment = voucher.create_adjustment(voucher.code, @order)

    unless adjustment.persisted?
      @order.errors.add(:voucher_code, I18n.t('split_checkout.errors.add_voucher_error'))
      adjustment.errors.each { |error| @order.errors.import(error) }
      return false
    end

    clear_payments

    VoucherAdjustmentsService.new(@order).update
    @order.update_totals_and_states

    true
  end

  def update_payment_section
    render cable_ready: cable_car.replace(
      selector: "#checkout-payment-methods",
      html: render_to_string(partial: "split_checkout/payment", locals: { step: "payment" })
    )
  end

  def render_error
    flash.now[:error] = @order.errors.full_messages.to_sentence

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash })).
      replace(
        "#voucher-section",
        partial(
          "split_checkout/voucher_section",
          locals: { order: @order, voucher_adjustment: @order.voucher_adjustments.first }
        )
      )
  end

  def voucher_params
    params.require(:order).permit(:voucher_code)
  end

  # Clear payments and payment fees, to not affect voucher adjustment calculation
  def clear_payments
    @order.all_adjustments.payment_fee.destroy_all
    @order.payments.clear
  end
end
