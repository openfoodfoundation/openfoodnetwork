require 'spree/core/controller_helpers/order_decorator'

Spree::OrdersController.class_eval do
  after_filter  :populate_variant_attributes, :only => :populate
  before_filter :update_distribution, :only => :update
  before_filter :filter_order_params, :only => :update

  # Patch Orders#populate to provide distributor_id and order_cycle_id to OrderPopulator
  def populate
    if OpenFoodNetwork::FeatureToggle.enabled? :multi_cart
      populate_cart params.slice(:products, :variants, :quantity, :distributor_id, :order_cycle_id)
    end

    populator = Spree::OrderPopulator.new(current_order(true), current_currency)
    if populator.populate(params.slice(:products, :variants, :quantity, :distributor_id, :order_cycle_id))
      fire_event('spree.cart.add')
      fire_event('spree.order.contents_changed')
      respond_with(@order) do |format|
        format.html { redirect_to cart_path }
      end
    else
      flash[:error] = populator.errors.full_messages.join(" ")
      redirect_to :back
    end
  end

  def select_distributor
    distributor = Enterprise.is_distributor.find params[:id]

    order = current_order(true)
    order.distributor = distributor
    order.save!

    redirect_to main_app.enterprise_path(distributor)
  end

  def deselect_distributor
    order = current_order(true)

    order.distributor = nil
    order.save!

    redirect_to root_path
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

end
