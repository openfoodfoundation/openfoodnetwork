class Shop::CheckoutController < Spree::CheckoutController
  layout 'darkswarm'

  prepend_before_filter :require_order_cycle
  prepend_before_filter :require_distributor_chosen
  skip_before_filter :check_registration

  include EnterprisesHelper
   
  def edit
  end

  def update
    if @order.update_attributes(params[:order])
      fire_event('spree.checkout.update')

      while @order.state != "complete"
        if @order.next
          state_callback(:after)
        else
          flash[:error] = t(:payment_processing_failed)
          respond_with @order, location: main_app.shop_checkout_path
          return
        end
      end

      if @order.state == "complete" ||  @order.completed?
        flash.notice = t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        respond_with(@order, :location => order_path(@order))
      else
        respond_with @order, location: main_app.shop_checkout_path
      end
    else
      respond_with @order, location: main_app.shop_checkout_path
    end
  end

  private

  def skip_state_validation?
    true
  end

  def set_distributor
    unless @distributor = current_distributor 
      redirect_to main_app.root_path
    end
  end

  def require_order_cycle
    unless current_order_cycle
      redirect_to main_app.shop_path
    end
  end
  
  def load_order
    @order = current_order
    redirect_to main_app.shop_path and return unless @order and @order.checkout_allowed?
    raise_insufficient_quantity and return if @order.insufficient_stock_lines.present?
    redirect_to main_app.shop_path and return if @order.completed?
    before_address
    state_callback(:before)
  end

  # Overriding Spree's methods
  def raise_insufficient_quantity
    flash[:error] = t(:spree_inventory_error_flash_for_insufficient_quantity)
    redirect_to main_app.shop_path
  end
end
