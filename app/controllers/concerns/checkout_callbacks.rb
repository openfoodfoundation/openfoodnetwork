# frozen_string_literal: true

module CheckoutCallbacks
  extend ActiveSupport::Concern
  include EnterprisesHelper

  included do
    # We need pessimistic locking to avoid race conditions.
    # Otherwise we fail on duplicate indexes or end up with negative stock.
    prepend_around_action CurrentOrderLocker, only: [:edit, :update]

    prepend_before_action :check_hub_ready_for_checkout
    prepend_before_action :check_order_cycle_expiry
    prepend_before_action :require_order_cycle
    prepend_before_action :require_distributor_chosen

    before_action :load_order, :associate_user, :load_saved_addresses, :load_saved_credit_cards
    before_action :load_shipping_methods, if: -> { params[:step] == "details" }

    before_action :ensure_order_not_completed
    before_action :ensure_checkout_allowed
    before_action :handle_insufficient_stock
    before_action :check_authorization
  end

  private

  def load_order
    @order = current_order
    @order.manual_shipping_selection = true
    @order.checkout_processing = true

    @voucher_adjustment = @order.vouchers.first

    redirect_to(main_app.shop_path) && return if redirect_to_shop?
    redirect_to_cart_path && return unless valid_order_line_items?
  end

  def load_saved_addresses
    finder = OpenFoodNetwork::AddressFinder.new(@order.email, @order.customer, spree_current_user)

    @order.bill_address ||= finder.bill_address
    @order.ship_address ||= finder.ship_address
  end

  def load_saved_credit_cards
    @saved_credit_cards = spree_current_user&.credit_cards&.with_payment_profile.to_a
    @selected_card = nil
  end

  def load_shipping_methods
    @shipping_methods = available_shipping_methods.sort { |a, b| a.name.casecmp(b.name) }
  end

  def redirect_to_shop?
    !@order ||
      !@order.checkout_allowed? ||
      @order.completed?
  end

  def redirect_to_cart_path
    respond_to do |format|
      format.html do
        redirect_to main_app.cart_path
      end

      format.json do
        render json: { path: main_app.cart_path }, status: :bad_request
      end
    end
  end

  def valid_order_line_items?
    @order.insufficient_stock_lines.empty? &&
      OrderCycleDistributedVariants.new(@order.order_cycle, @order.distributor).
        distributes_order_variants?(@order)
  end

  def ensure_order_not_completed
    redirect_to main_app.cart_path if @order.completed?
  end

  def ensure_checkout_allowed
    redirect_to main_app.cart_path unless @order.checkout_allowed?
  end

  def check_authorization
    authorize!(:edit, current_order, session[:access_token])
  end
end
