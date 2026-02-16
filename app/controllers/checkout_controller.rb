# frozen_string_literal: true

require 'open_food_network/address_finder'

class CheckoutController < BaseController
  layout 'darkswarm'

  include OrderStockCheck
  include Spree::BaseHelper
  include CheckoutCallbacks
  include CheckoutSteps
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
    if params[:step].blank?
      redirect_to_step_based_on_order
    else
      handle_insufficient_stock if details_step?
      update_order_state
      check_step
    end

    if payment_step? || summary_step?
      credit_payment_method = @order.distributor.payment_methods.customer_credit
      @paid_with_credit = @order.payments.find_by(payment_method: credit_payment_method)&.amount
    end

    return if available_shipping_methods.any?

    flash[:error] = I18n.t('checkout.errors.no_shipping_methods_available')
  end

  def update
    return render cable_ready: cable_car.redirect_to(url: checkout_step_path(:details)) \
      unless sufficient_stock?

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
    flash.now[:error] ||= I18n.t('checkout.errors.saving_failed')

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#checkout", partial("checkout/checkout")).
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash }))
  end

  def check_payments_adjustments
    @order.payments.each(&:ensure_correct_adjustment)
  end

  def clear_invalid_payments
    @order.payments.with_state(:invalid).delete_all
  end

  def confirm_order
    return unless summary_step? && @order.confirmation?
    return unless validate_current_step

    @order.customer.touch :terms_and_conditions_accepted_at

    # Redeem VINE voucher
    vine_voucher_redeemer = Vine::VoucherRedeemerService.new(order: @order)
    unless vine_voucher_redeemer.redeem
      # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
      flash[:error] = if vine_voucher_redeemer.errors.keys.include?(:redeeming_failed)
                        vine_voucher_redeemer.errors[:redeeming_failed]
                      else
                        I18n.t('checkout.errors.voucher_redeeming_error')
                      end
      return false
      # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
    end

    return true if redirect_to_payment_gateway

    @order.process_payments!
    @order.confirm!
    BackorderJob.check_stock(@order)
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

  def update_order # rubocop:disable Metrics/CyclomaticComplexity
    return if params[:confirm_order] || @order.errors.any?

    # Checking if shipping method updated before @order get updated. We can't use this guard
    # clause in recalculate_voucher as by then the @order.shipping method would be the new one
    shipping_method_updated = @order.shipping_method&.id != params[:shipping_method_id].to_i

    @order.select_shipping_method(params[:shipping_method_id])

    @order.update(order_params)

    add_payment_with_credit if credit_available? && details_step?

    # We need to update voucher to take into account:
    #  * when moving away from "details" step : potential change in shipping method fees
    #  * when moving away from "payment" step : payment fees
    recalculate_voucher(shipping_method_updated) if details_step? || payment_step?
    @order.update_totals_and_states

    validate_current_step
  end

  def recalculate_voucher(shipping_method_updated)
    return if @order.voucher_adjustments.empty?

    return unless shipping_method_updated

    VoucherAdjustmentsService.new(@order).update
  end

  def credit_available?
    return false if @order.customer.nil?

    available_credit > 0
  end

  def add_payment_with_credit
    credit_payment_method = @order.distributor.payment_methods.customer_credit

    if credit_payment_method.nil?
      error_message = "Customer credit payment method is missing, please check configuration"
      log_error(error_message)
      return
    end

    return if @order.payments.where(payment_method: credit_payment_method).exists?

    # we are already in a transaction because the order is locked, so we force creating a new one
    # to make sure the rollback works as expected :
    # https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
    ActiveRecord::Base.transaction(requires_new: true) do
      amount = [available_credit, @order.total].min
      payment = @order.payments.create!(payment_method: credit_payment_method, amount:)
      payment.internal_purchase!
    end
  rescue StandardError => e
    # Even though the transaction rolled back, the order still have a payment in memory,
    # so we reload the payments so the payment doesn't get saved later on
    @order.payments.reload
    log_error(e)
  end

  def available_credit
    @available_credit ||= @order.customer.customer_account_transactions.last&.balance || 0.00
  end

  def validate_current_step
    Checkout::Validation.new(@order, params).call && @order.errors.empty?
  end

  def advance_order_state
    return if @order.complete?

    Orders::WorkflowService.new(@order).advance_checkout(raw_params.slice(:shipping_method_id))
  end

  def order_params
    @order_params ||= Checkout::Params.new(@order, params, spree_current_user).call
  end

  # Update order state based on the step we are loading to avoid discrepancy between step and order
  # state. We need to do this when moving back to a previous checkout step, the update action takes
  # care of moving the order state forward.
  def update_order_state
    return @order.back_to_payment if @order.confirmation? && payment_step?

    return unless @order.after_delivery_state? && details_step?

    @order.back_to_address
  end

  def log_error(error)
    Rails.logger.error("CheckoutController: #{error}")
    Alert.raise(error)
  end
end
