Spree::OrdersController.class_eval do
  before_filter :populate_order_distributor, :only => :populate
  after_filter :populate_variant_attributes, :only => :populate

  def populate_order_distributor
    @distributor = params.key?(:distributor_id) ? Spree::Distributor.find(params[:distributor_id]) : nil

    if populate_valid? @distributor
      order = current_order(true)
      order.distributor = @distributor
      order.save!

    else
      redirect_to cart_path
    end
  end

  def populate_variant_attributes
    if params.key? :variant_attributes
      params[:variant_attributes].each do |variant_id, attributes|
        attributes.each do |k, v|
          @order.set_variant_attribute(Spree::Variant.find(variant_id), k, v)
        end
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
end
