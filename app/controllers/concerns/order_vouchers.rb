# frozen_string_literal: true

module OrderVouchers
  extend ActiveSupport::Concern

  private

  def render_voucher_section_or_redirect
    respond_to do |format|
      format.cable_ready { render_voucher_section }
      format.html { redirect_to checkout_step_path(:payment) }
    end
  end

  # Using the power of cable_car we replace only the #voucher_section instead of reloading the page
  def render_voucher_section
    render(
      status: :ok,
      cable_ready: cable_car.replace(
        "#voucher-section",
        partial(
          "split_checkout/voucher_section",
          locals: { order: @order, voucher_adjustment: @order.voucher_adjustments.first }
        )
      )
    )
  end

  def process_voucher
    if add_voucher
      VoucherAdjustmentsService.calculate(@order)
      render_voucher_section_or_redirect
    elsif @order.errors.present?
      render_error
    end
  end

  def add_voucher
    if params.dig(:order, :voucher_code).blank?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.voucher_not_found'))
      return false
    end

    # Fetch Voucher
    voucher = Voucher.find_by(code: params[:order][:voucher_code], enterprise: @order.distributor)

    if voucher.nil?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.voucher_not_found'))
      return false
    end

    adjustment = voucher.create_adjustment(voucher.code, @order)

    unless adjustment.valid?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.add_voucher_error'))
      adjustment.errors.each { |error| @order.errors.import(error) }
      return false
    end

    true
  end
end
