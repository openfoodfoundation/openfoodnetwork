module SharedHelper
  def distributor_link_class(distributor)
    cart = current_order(true)
    @active_distributors ||= Enterprise.distributors_with_active_order_cycles

    klass = "shop-distributor"
    klass += " empties-cart" unless cart.line_items.empty? || cart.distributor == distributor
    klass += @active_distributors.include?(distributor) ? ' active' : ' inactive'
    klass
  end

  # all suppliers of current distributor's products
  def current_producers
    Exchange.where(receiver_id: current_distributor.id).map{ |ex| ex.variants.map {|v| v.product.supplier }}.flatten.uniq 
  end
end

