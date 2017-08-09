Spree::Admin::LineItemsController.class_eval do
  prepend_before_filter :load_order, except: :index
  around_filter :apply_enterprise_fees_with_lock, only: :update

  def create
    variant = Spree::Variant.find(params[:line_item][:variant_id])
    OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)

    @line_item = @order.add_variant(variant, params[:line_item][:quantity].to_i)

    if @order.save
      respond_with(@line_item) do |format|
        format.html { render :partial => 'spree/admin/orders/form', :locals => { :order => @order.reload } }
      end
    else
      respond_with(@line_item) do |format|
        format.js { render :action => 'create', :locals => { :order => @order.reload } }
      end
    end
  end

  # TODO: simplify this, 3 formats per action is too much
  #       we need `js` format for admin/orders/edit (jquery-rails gem)
  #       we don't know if `html` format is needed
  def update
    respond_to do |format|
      format.html { render_order_form }
      format.js {
        if @line_item.update_attributes(params[:line_item])
          render nothing: true, status: 204 # No Content, does not trigger ng resource auto-update
        else
          render json: { errors: @line_item.errors }, status: 412
        end
      }
    end
  end

  # TODO: simplify this, 3 formats per action is too much:
  #       we need `js` format for admin/orders/edit (jquery-rails gem)
  #       we don't know if `html` format is needed
  def destroy
    @line_item.destroy

    respond_to do |format|
      format.html { render_order_form }
      format.js { render nothing: true, status: 204 } # No Content
    end
  end

  private

  def render_order_form
    respond_to do |format|
      format.html { render partial: 'spree/admin/orders/form', locals: {order: @order.reload} }
    end
  end

  def load_order
    @order = Spree::Order.find_by_number!(params[:order_id])
    authorize! :update, @order
  end

  def apply_enterprise_fees_with_lock
    authorize! :read, @order
    @order.with_lock do
      yield
      @order.update_distribution_charge!
    end
  end
end
