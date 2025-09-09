# frozen_string_literal: true

class VoucherAdjustmentsController < BaseController
  before_action :set_order

  def create
    if voucher_params[:voucher_code].blank?
      @order.errors.add(:voucher_code, I18n.t('checkout.errors.voucher_code_blank'))
      return render_error
    end

    voucher = load_voucher

    return render_error unless valid_voucher?(voucher)

    if add_voucher_to_order(voucher)
      update_payment_section
    elsif @order.errors.present?
      render_error
    end
  end

  def destroy
    # An order can have more than one adjustment linked to one voucher
    adjustment = @order.voucher_adjustments.find_by(id: params[:id])
    if adjustment.present?
      @order.voucher_adjustments.where(originator_id: adjustment.originator_id)&.destroy_all
    end

    # Update order to make sure we display the appropriate payment method
    @order.update_totals_and_states

    update_payment_section
  end

  private

  def set_order
    @order = current_order
  end

  def valid_voucher?(voucher)
    return false if @order.errors.present?

    if voucher.nil?
      @order.errors.add(:voucher_code, I18n.t('checkout.errors.voucher_code_not_found'))
      return false
    end

    if !voucher.valid?
      @order.errors.add(
        :voucher_code,
        I18n.t(
          'checkout.errors.create_voucher_error', error: voucher.errors.full_messages.to_sentence
        )
      )
      return false
    end

    true
  end

  def add_voucher_to_order(voucher)
    adjustment = voucher.create_adjustment(voucher.code, @order)

    unless adjustment.persisted?
      @order.errors.add(:voucher_code, I18n.t('checkout.errors.add_voucher_error'))
      adjustment.errors.each { |error| @order.errors.import(error) }
      return false
    end

    # calculate_voucher_adjustment
    clear_payments

    OrderManagement::Order::Updater.new(@order).update_voucher

    true
  end

  def load_voucher
    voucher = Voucher.find_by(code: voucher_params[:voucher_code],
                              enterprise: @order.distributor)
    return voucher unless voucher.nil? || voucher.is_a?(Vouchers::Vine)

    vine_voucher
  end

  def vine_voucher
    vine_voucher_validator = Vine::VoucherValidatorService.new(
      voucher_code: voucher_params[:voucher_code], enterprise: @order.distributor
    )
    voucher = vine_voucher_validator.validate
    errors = vine_voucher_validator.errors

    return nil if errors[:not_found_voucher].present?

    if errors.present?
      message = errors[:invalid_voucher] || I18n.t('checkout.errors.add_voucher_error')
      @order.errors.add(:voucher_code, message)
      return nil
    end

    voucher
  end

  def update_payment_section
    render cable_ready: cable_car.replace(
      selector: "#checkout-payment-methods",
      html: render_to_string(partial: "checkout/payment", locals: { step: "payment" })
    )
  end

  def render_error
    flash.now[:error] = @order.errors.full_messages.to_sentence

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash })).
      replace(
        "#voucher-section",
        partial(
          "checkout/voucher_section",
          locals: { order: @order, voucher_adjustment: @order.voucher_adjustments.first }
        )
      )
  end

  def voucher_params
    params.require(:order).permit(:voucher_code)
  end

  # Clear payments and payment fees, to not affect voucher adjustment calculation
  def clear_payments
    @order.payments.incomplete.destroy_all
  end
end
