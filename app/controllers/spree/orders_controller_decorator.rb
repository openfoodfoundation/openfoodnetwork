require 'spree/core/controller_helpers/order_decorator'

Spree::OrdersController.class_eval do
  after_filter  :populate_variant_attributes, only: :populate
  before_filter :update_distribution, only: :update
  before_filter :filter_order_params, only: :update

  prepend_before_filter :require_order_cycle, only: :edit
  prepend_before_filter :require_distributor_chosen, only: :edit
  before_filter :check_hub_ready_for_checkout, only: :edit
  before_filter :check_at_least_one_line_item, only: :update

  include OrderCyclesHelper
  layout 'darkswarm'

  respond_to :json

  # Patching to redirect to shop if order is empty
  def edit
    @order = current_order(true)
    @insufficient_stock_lines = @order.insufficient_stock_lines

    if @order.line_items.empty?
      redirect_to main_app.shop_path
    else
      associate_user

      if @order.insufficient_stock_lines.present?
        flash[:error] = t(:spree_inventory_error_flash_for_insufficient_quantity)
      end
    end
  end

  def update
    @insufficient_stock_lines = []
    @order = order_to_update
    unless @order
      flash[:error] = t(:order_not_found)
      redirect_to root_path and return
    end

    if @order.update_attributes(params[:order])
      @order.line_items = @order.line_items.select {|li| li.quantity > 0 }

      render :edit and return unless apply_coupon_code

      if @order == current_order
        fire_event('spree.order.contents_changed')
      else
        @order.update_distribution_charge!
      end

      respond_with(@order) do |format|
        format.html do
          if params.has_key?(:checkout)
            @order.next_transition.run_callbacks if @order.cart?
            redirect_to checkout_state_path(@order.checkout_steps.first)
          elsif @order.complete?
            redirect_to order_path(@order)
          else
            redirect_to cart_path
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

  def populate
    # Without intervention, the Spree::Adjustment#update_adjustable callback is called many times
    # during cart population, for both taxation and enterprise fees. This operation triggers a
    # costly Spree::Order#update!, which only needs to be run once. We avoid this by disabling
    # callbacks on Spree::Adjustment and then manually invoke Spree::Order#update! on success.

    Spree::Adjustment.without_callbacks do
      populator = Spree::OrderPopulator.new(current_order(true), current_currency)

      if populator.populate(params.slice(:products, :variants, :quantity), true)
        fire_event('spree.cart.add')
        fire_event('spree.order.contents_changed')

        current_order.cap_quantity_at_stock!
        current_order.update!

        variant_ids = variant_ids_in(populator.variants_h)

        render json: {error: false, stock_levels: stock_levels(current_order, variant_ids)},
               status: 200

      else
        render json: {error: true}, status: 412
      end
    end
  end

  # Report the stock levels in the order for all variant ids requested
  def stock_levels(order, variant_ids)
    stock_levels = li_stock_levels(order)

    li_variant_ids = stock_levels.keys
    (variant_ids - li_variant_ids).each do |variant_id|
      stock_levels[variant_id] = {quantity: 0, max_quantity: 0,
                                  on_hand: Spree::Variant.find(variant_id).on_hand}
    end

    stock_levels
  end

  def variant_ids_in(variants_h)
    variants_h.map { |v| v[:variant_id].to_i }
  end

  def li_stock_levels(order)
    Hash[
      order.line_items.map do |li|
        [li.variant.id,
         {quantity: li.quantity,
          max_quantity: li.max_quantity,
          on_hand: wrap_json_infinity(li.variant.on_hand)}]
      end
    ]
  end

  def update_distribution
    @order = current_order(true)

    if params[:commit] == 'Choose Hub'
      distributor = Enterprise.is_distributor.find params[:order][:distributor_id]
      @order.set_distributor! distributor

      flash[:notice] = 'Your hub has been selected.'
      redirect_to request.referer

    elsif params[:commit] == 'Choose Order Cycle'
      @order.empty! # empty cart
      order_cycle = OrderCycle.active.find params[:order][:order_cycle_id]
      @order.set_order_cycle! order_cycle

      flash[:notice] = 'Your order cycle has been selected.'
      redirect_to request.referer
    end
  end

  def filter_order_params
    if params[:order] and params[:order][:line_items_attributes]
      params[:order][:line_items_attributes] = remove_missing_line_items(params[:order][:line_items_attributes])
    end
  end

  def remove_missing_line_items(attrs)
    attrs.select do |i, line_item|
      Spree::LineItem.find_by_id(line_item[:id])
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
    @order = Spree::Order.find_by_number!(params[:id])
    authorize! :cancel, @order

    if @order.cancel
      flash[:success] = I18n.t(:orders_your_order_has_been_cancelled)
    else
      flash[:error] = I18n.t(:orders_could_not_cancel)
    end
    redirect_to request.referer || order_path(@order)
  end


  private

  def populate_variant_attributes
    order = current_order.reload

    if params.key? :variant_attributes
      params[:variant_attributes].each do |variant_id, attributes|
        order.set_variant_attributes(Spree::Variant.find(variant_id), attributes)
      end
    end

    if params.key? :quantity
      params[:products].each do |product_id, variant_id|
        max_quantity = params[:max_quantity].to_i
        order.set_variant_attributes(Spree::Variant.find(variant_id),
                                             {:max_quantity => max_quantity})
      end
    end
  end

  def populate_cart hash
    if spree_current_user
      unless spree_current_user.cart
        spree_current_user.build_cart
        cart = Cart.create(user: spree_current_user)
        spree_current_user.cart = cart
        spree_current_user.save
      end
      distributor = Enterprise.find(hash[:distributor_id])
      order_cycle = OrderCycle.find(hash[:order_cycle_id]) if hash[:order_cycle_id]
      spree_current_user.cart.add_variant hash[:variants].keys.first, hash[:variants].values.first, distributor, order_cycle, current_currency
    end
  end

  # Rails to_json encodes Float::INFINITY as Infinity, which is not valid JSON
  # Return it as a large integer (max 32 bit signed int)
  def wrap_json_infinity(n)
    n == Float::INFINITY ? 2147483647 : n
  end

  def order_to_update
    return @order_to_update if defined? @order_to_update
    return @order_to_update = current_order unless params[:id]
    @order_to_update = changeable_order_from_number
  end

  # If a specific order is requested, return it if it is COMPLETE and
  # changes are allowed and the user has access. Return nil if not.
  def changeable_order_from_number
    order = Spree::Order.complete.find_by_number(params[:id])
    return nil unless order.andand.changes_allowed? && can?(:update, order)
    order
  end

  def check_at_least_one_line_item
    return unless order_to_update.andand.complete?

    items = params[:order][:line_items_attributes]
    .andand.select{ |k,attrs| attrs["quantity"].to_i > 0 }

    if items.empty?
      flash[:error] = I18n.t(:orders_cannot_remove_the_final_item)
      redirect_to order_path(order_to_update)
    end
  end
end
