Spree::OrdersController.class_eval do
  before_filter :populate_order_distributor,  :only => :populate
  after_filter  :populate_variant_attributes, :only => :populate

  def populate_order_distributor
    @distributor = params[:distributor_id].present? ? Enterprise.is_distributor.find(params[:distributor_id]) : nil

    if populate_valid? @distributor
      order = current_order(true)
      order.set_distributor! @distributor

    else
      flash[:error] = "Please choose a distributor for this order." if @distributor.nil?
      redirect_populate_to_first_product
    end
  end

  def populate_variant_attributes
    if params.key? :variant_attributes
      params[:variant_attributes].each do |variant_id, attributes|
        @order.set_variant_attributes(Spree::Variant.find(variant_id), attributes)
      end
    end

    if params.key? :quantity
      params[:products].each do |product_id, variant_id|
        max_quantity = params[:max_quantity].to_i
        @order.set_variant_attributes(Spree::Variant.find(variant_id), {:max_quantity => max_quantity})
      end
    end
  end


  private

  def populate_valid? distributor
    # -- Distributor must be specified
    return false if distributor.nil?

    # -- All products must be available under that distributor
    params[:products].each do |product_id, variant_id|
      product = Spree::Product.find product_id
      return false unless product.distributors.include? distributor
    end if params[:products]

    params[:variants].each do |variant_id, quantity|
      variant = Spree::Variant.find variant_id
      return false unless variant.product.distributors.include? distributor
    end if params[:variants]

    # -- If products in cart, distributor can't be changed
    order = current_order(false)
    if !order.nil? && !order.can_change_distributor? && order.distributor != distributor
      return false
    end

    true
  end

  def redirect_populate_to_first_product
    product = if params[:products].present?
                Spree::Product.find(params[:products].keys.first)
              else
                Spree::Variant.find(params[:variants].keys.first).product
              end

    redirect_to product
  end
end
