# frozen_string_literal: true

require 'open_food_network/address_finder'

class SplitCheckoutController < ::BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper
  include CheckoutCallbacks
  include OrderCompletion
  include CablecarResponses
  include WhiteLabel

  helper 'terms_and_conditions'
  helper 'checkout'
  helper 'spree/orders'
  helper EnterprisesHelper
  helper OrderHelper

  before_action :set_checkout_redirect
  before_action :hide_ofn_navigation, only: [:edit, :update]

  def edit
    #  TODO Calculate percent amount covered by the voucher for display purposes
    @voucher_adjustment = @order.vouchers.first

    redirect_to_step_based_on_order unless params[:step]
    check_step if params[:step]
    recalculate_tax if params[:step] == "summary"

    flash_error_when_no_shipping_method_available if available_shipping_methods.none?
  end

  def update
    return add_voucher if payment_step? and params[:order][:voucher_code]

    if confirm_order || update_order
      return if performed?

      check_payments_adjustments
      clear_invalid_payments
      advance_order_state
      redirect_to_step
    else
      render_error
    end
  rescue Spree::Core::GatewayError => e
    flash[:error] = I18n.t(:spree_gateway_error_flash_for_checkout, error: e.message)
    @order.update_column(:state, "payment")
    render cable_ready: cable_car.redirect_to(url: checkout_step_path(:payment))
  end

  private

  def render_error
    flash.now[:error] ||= I18n.t(
      'split_checkout.errors.saving_failed',
      messages: order_error_messages
    )

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#checkout", partial("split_checkout/checkout")).
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash }))
  end

  def order_error_messages
    # Remove ship_address.* errors if no shipping method is not selected
    remove_ship_address_errors if no_ship_address_needed?

    # Reorder errors to make sure the most important ones are shown first
    # and finally, return the error messages to sentence
    reorder_errors.map(&:full_message).to_sentence
  end

  def no_ship_address_needed?
    @order.errors[:shipping_method].present? || params[:ship_address_same_as_billing] == "1"
  end

  def remove_ship_address_errors
    @order.errors.delete("ship_address.firstname")
    @order.errors.delete("ship_address.address1")
    @order.errors.delete("ship_address.city")
    @order.errors.delete("ship_address.phone")
    @order.errors.delete("ship_address.lastname")
    @order.errors.delete("ship_address.zipcode")
  end

  def reorder_errors
    @order.errors.sort_by do |e|
      case e.attribute
      when /email/i then 0
      when /phone/i then 1
      when /bill_address/i then 2 + bill_address_error_order(e)
      else 20
      end
    end
  end

  def bill_address_error_order(error)
    case error.attribute
    when /firstname/i then 0
    when /lastname/i then 1
    when /address1/i then 2
    when /city/i then 3
    when /zipcode/i then 4
    else 5
    end
  end

  def flash_error_when_no_shipping_method_available
    flash[:error] = I18n.t('split_checkout.errors.no_shipping_methods_available')
  end

  def check_payments_adjustments
    @order.payments.each(&:ensure_correct_adjustment)
  end

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless summary_step? && @order.confirmation?
    return unless validate_summary! && @order.errors.empty?

    @order.customer.touch :terms_and_conditions_accepted_at

    return true if redirect_to_payment_gateway

    @order.process_payments!
    @order.confirm!
    order_completion_reset @order
  end

  def redirect_to_payment_gateway
    return unless selected_payment_method&.external_gateway?
    return unless (redirect_url = selected_payment_method.external_payment_url(order: @order))

    render cable_ready: cable_car.redirect_to(url: redirect_url)
    true
  end

  def selected_payment_method
    @selected_payment_method ||= Checkout::PaymentMethodFetcher.new(@order).call
  end

  def update_order
    return if params[:confirm_order] || @order.errors.any?

    # If we have "pick up" shipping method (require_ship_address is set to false), use the
    # distributor address as shipping address
    use_shipping_address_from_distributor if shipping_method_ship_address_not_required?

    @order.select_shipping_method(params[:shipping_method_id])
    @order.update(order_params)
    @order.updater.update_totals_and_states

    validate_current_step!

    @order.errors.empty?
  end

  def use_shipping_address_from_distributor
    @order.ship_address = @order.address_from_distributor

    # Add the missing data
    bill_address = params[:order][:bill_address_attributes]
    @order.ship_address.firstname = bill_address[:firstname]
    @order.ship_address.lastname = bill_address[:lastname]
    @order.ship_address.phone = bill_address[:phone]

    # Remove shipping address from parameter so we don't override the address we just set
    params[:order].delete(:ship_address_attributes)
  end

  def shipping_method_ship_address_not_required?
    selected_shipping_method = available_shipping_methods&.select do |sm|
      sm.id.to_s == params[:shipping_method_id]
    end

    return false if selected_shipping_method.empty?

    selected_shipping_method.first.require_ship_address == false
  end

  def add_voucher
    # Fetch Voucher
    voucher = Voucher.find_by(code: params[:order][:voucher_code], enterprise: @order.distributor)

    if voucher.nil?
      @order.errors.add(:voucher, I18n.t('split_checkout.errors.voucher_not_found'))
      return render_error
    end

    # Create adjustment
    # TODO add tax part of adjustement
    voucher.create_adjustment(voucher.code, @order)

    redirect_to checkout_step_path(:payment)
  end

  def summary_step?
    params[:step] == "summary"
  end

  def payment_step?
    params[:step] == "payment"
  end

  def advance_order_state
    return if @order.complete?

    OrderWorkflow.new(@order).advance_checkout(raw_params.slice(:shipping_method_id))
  end

  def validate_current_step!
    step = ([params[:step]] & ["details", "payment", "summary"]).first
    send("validate_#{step}!")
  end

  def validate_details!
    return true if params[:shipping_method_id].present?

    @order.errors.add :shipping_method, I18n.t('split_checkout.errors.select_a_shipping_method')
  end

  def validate_payment!
    return true if params.dig(:order, :payments_attributes, 0, :payment_method_id).present?

    @order.errors.add :payment_method, I18n.t('split_checkout.errors.select_a_payment_method')
  end

  def validate_summary!
    return true if params[:accept_terms]
    return true unless TermsOfService.required?(@order.distributor)

    @order.errors.add(:terms_and_conditions, t("split_checkout.errors.terms_not_accepted"))
  end

  def order_params
    @order_params ||= Checkout::Params.new(@order, params, spree_current_user).call
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
      redirect_to checkout_step_path(:details) unless params[:step] == "details"
    when "payment"
      redirect_to checkout_step_path(:payment) if params[:step] == "summary"
    end
  end

  def recalculate_tax
    @order.create_tax_charge!
    @order.update_order!
  end
end
