# frozen_string_literal: true

module CheckoutSteps
  extend ActiveSupport::Concern

  private

  def summary_step?
    params[:step] == "summary"
  end

  def payment_step?
    params[:step] == "payment"
  end

  def details_step?
    params[:step] == "details"
  end

  def redirect_to_step_based_on_order
    case @order.state
    when "cart", "address", "delivery"
      redirect_to checkout_step_path(:details)
    when "payment"
      redirect_to checkout_step_path(:payment)
    when "confirmation"
      redirect_to checkout_step_path(:summary)
    else
      redirect_to order_path(@order, order_token: @order.token)
    end
  end

  def redirect_to_step
    case params[:step]
    when "details"
      return redirect_to checkout_step_path(:payment)
    when "payment"
      return redirect_to checkout_step_path(:summary)
    end
    redirect_to_step_based_on_order
  end

  def check_step
    case @order.state
    when "cart", "address", "delivery"
      redirect_to checkout_step_path(:details) unless details_step?
    when "payment"
      redirect_to checkout_step_path(:payment) if summary_step?
    end
  end

  def update_order_state
    if @order.state == "confirmation" && payment_step?
      @order.back_to_payment
    end

    return unless @order.state.in?(["payment", "confirmation"]) && details_step?

    @order.back_to_address
  end
end
