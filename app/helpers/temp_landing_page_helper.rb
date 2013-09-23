module TempLandingPageHelper
  def temp_landing_page_distributor_link_class(distributor)
    cart = current_order(true)

    klass = "shop-distributor"
    klass += " empties-cart" unless cart.line_items.empty? || cart.distributor == distributor
    klass
  end
end
