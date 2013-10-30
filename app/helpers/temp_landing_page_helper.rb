module TempLandingPageHelper
  def temp_landing_page_distributor_link_class(distributor)
    cart = current_order(true)
    @active_distributors ||= Enterprise.active_distributors

    klass = "shop-distributor"
    klass += " empties-cart" unless cart.line_items.empty? || cart.distributor == distributor
    klass += @active_distributors.include?(distributor) ? ' active' : ' inactive'
    klass
  end
end
