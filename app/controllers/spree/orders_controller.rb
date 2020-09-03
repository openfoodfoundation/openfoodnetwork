require 'spree/core/controller_helpers/order'
require 'spree/core/controller_helpers/auth'

module Spree
  class OrdersController < Spree::StoreController
    include OrderCyclesHelper
    layout 'darkswarm'

    ssl_required :show

    before_action :check_authorization
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    helper 'spree/products', 'spree/orders'

    respond_to :html
    respond_to :json

    before_action :update_distribution, only: :update
    before_action :filter_order_params, only: :update
    before_action :enable_embedded_shopfront

    prepend_before_action :require_order_authentication, only: :show
    prepend_before_action :require_order_cycle, only: :edit
    prepend_before_action :require_distributor_chosen, only: :edit
    before_action :check_hub_ready_for_checkout, only: :edit
    before_action :check_at_least_one_line_item, only: :update

    def show
      @order = Spree::Order.find_by!(number: params[:id])
    end

    def empty
      if @order = current_order
        @order.empty!
      end

      redirect_to main_app.cart_path
    end

    def check_authorization
      session[:access_token] ||= params[:token]
      order = Spree::Order.find_by(number: params[:id]) || current_order

      if order
        authorize! :edit, order, session[:access_token]
      else
        authorize! :create, Spree::Order
      end
    end

    # Patching to redirect to shop if order is empty
    def edit
      @order = current_order(true)
      @insufficient_stock_lines = @order.insufficient_stock_lines
      @unavailable_order_variants = OrderCycleDistributedVariants.
        new(current_order_cycle, current_distributor).unavailable_order_variants(@order)

      if @order.line_items.empty?
        redirect_to main_app.shop_path
      else
        associate_user

        if @order.insufficient_stock_lines.present? || @unavailable_order_variants.present?
          flash[:error] = t("spree.orders.error_flash_for_unavailable_items")
        end
      end
    end

    def update
      @insufficient_stock_lines = []
      @order = order_to_update
      unless @order
        flash[:error] = t(:order_not_found)
        redirect_to(main_app.root_path) && return
      end

      if @order.update(order_params)
        discard_empty_line_items
        with_open_adjustments { update_totals_and_taxes }

        if @order == current_order
          fire_event('spree.order.contents_changed')
        else
          @order.update_distribution_charge!
        end

        respond_with(@order) do |format|
          format.html do
            if params.key?(:checkout)
              @order.next_transition.run_callbacks if @order.cart?
              redirect_to checkout_state_path(@order.checkout_steps.first)
            elsif @order.complete?
              redirect_to spree.order_path(@order)
            else
              redirect_to main_app.cart_path
            end
          end
        end
      else
        # Show order with original values, not newly entered ones
        @insufficient_stock_lines = @order.insufficient_stock_lines
        @order.line_items(true)
        respond_with(@order)
      end
    end

    def update_distribution
      @order = current_order(true)

      if params[:commit] == 'Choose Hub'
        distributor = Enterprise.is_distributor.find params[:order][:distributor_id]
        @order.set_distributor! distributor

        flash[:notice] = I18n.t(:order_choosing_hub_notice)
        redirect_to request.referer

      elsif params[:commit] == 'Choose Order Cycle'
        @order.empty! # empty cart
        order_cycle = OrderCycle.active.find params[:order][:order_cycle_id]
        @order.set_order_cycle! order_cycle

        flash[:notice] = I18n.t(:order_choosing_hub_notice)
        redirect_to request.referer
      end
    end

    def filter_order_params
      if params[:order] && params[:order][:line_items_attributes]
        params[:order][:line_items_attributes] =
          remove_missing_line_items(params[:order][:line_items_attributes])
      end
    end

    def remove_missing_line_items(attrs)
      attrs.select do |_i, line_item|
        Spree::LineItem.find_by(id: line_item[:id])
      end
    end

    def clear
      @order = current_order(true)
      @order.empty!
      @order.set_order_cycle! nil
      redirect_to main_app.enterprise_path(@order.distributor.id)
    end

    def order_cycle_expired
      @order_cycle = OrderCycle.find session[:expired_order_cycle_id]
    end

    def cancel
      @order = Spree::Order.find_by!(number: params[:id])
      authorize! :cancel, @order

      if @order.cancel
        flash[:success] = I18n.t(:orders_your_order_has_been_cancelled)
      else
        flash[:error] = I18n.t(:orders_could_not_cancel)
      end
      redirect_to request.referer || spree.order_path(@order)
    end

    private

    # Updates the various denormalized total attributes of the order and
    # recalculates the shipment taxes
    def update_totals_and_taxes
      @order.updater.update_totals
      @order.shipment&.ensure_correct_adjustment
    end

    # Sets the adjustments to open to perform the block's action and restores
    # their state to whatever the they had. Note that it does not change any new
    # adjustments that might get created in the yielded block.
    def with_open_adjustments
      previous_states = @order.adjustments.each_with_object({}) do |adjustment, hash|
        hash[adjustment.id] = adjustment.state
      end
      @order.adjustments.each { |adjustment| adjustment.fire_events(:open) }

      yield

      @order.adjustments.each do |adjustment|
        previous_state = previous_states[adjustment.id]
        adjustment.update_attribute(:state, previous_state) if previous_state
      end
    end

    def discard_empty_line_items
      @order.line_items = @order.line_items.select { |li| li.quantity > 0 }
    end

    def require_order_authentication
      return if session[:access_token] || params[:token] || spree_current_user

      flash[:error] = I18n.t("spree.orders.edit.login_to_view_order")
      redirect_to main_app.root_path(anchor: "login?after_login=#{request.env['PATH_INFO']}")
    end

    def order_to_update
      return @order_to_update if defined? @order_to_update
      return @order_to_update = current_order unless params[:id]

      @order_to_update = changeable_order_from_number
    end

    # If a specific order is requested, return it if it is COMPLETE and
    # changes are allowed and the user has access. Return nil if not.
    def changeable_order_from_number
      order = Spree::Order.complete.find_by(number: params[:id])
      return nil unless order.andand.changes_allowed? && can?(:update, order)

      order
    end

    def check_at_least_one_line_item
      return unless order_to_update.andand.complete?

      items = params[:order][:line_items_attributes]
        .andand.select{ |_k, attrs| attrs["quantity"].to_i > 0 }

      if items.empty?
        flash[:error] = I18n.t(:orders_cannot_remove_the_final_item)
        redirect_to spree.order_path(order_to_update)
      end
    end

    def order_params
      params.require(:order).permit(
        :distributor_id, :order_cycle_id,
        line_items_attributes: [:id, :quantity]
      )
    end
  end
end
