Spree::OrdersController.class_eval do
  before_filter :populate_order_distributor, :only => :populate

  def populate_order_distributor
    @distributor = Spree::Distributor.find params[:distributor_id]

    if populate_valid? @distributor
      order = current_order(true)
      order.distributor = @distributor
      order.save!

    else
      redirect_to cart_path
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

    true
  end
end
