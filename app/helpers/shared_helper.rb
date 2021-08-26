# frozen_string_literal: true

module SharedHelper
  def distributor_link_class(distributor)
    cart = current_order(true)
    @active_distributors ||= Enterprise.distributors_with_active_order_cycles

    klass = "shop-distributor"
    klass += " empties-cart" unless cart.line_items.empty? || cart.distributor == distributor
    klass += @active_distributors.include?(distributor) ? ' active' : ' inactive'
    klass
  end

  def enterprise_user?
    spree_current_user&.enterprises&.count.to_i > 0
  end

  def admin_user?
    spree_current_user&.has_spree_role? 'admin'
  end

  def current_shop_products_path
    "#{main_app.enterprise_shop_path(current_distributor)}#/shop"
  end
end
