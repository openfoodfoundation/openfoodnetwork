# frozen_string_literal: true

class VoucherAdjustmentsController < ::BaseController
  include CablecarResponses

  def destroy
    @order = current_order

    # TODO: do we need to check the user can delete voucher_adjustment
    @order.voucher_adjustments.find_by(id: params[:id])&.destroy

    respond_to do |format|
      format.cable_ready { render_voucher_section }
      format.html { redirect_to checkout_step_path(:payment) }
    end
  end

  private

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
end
