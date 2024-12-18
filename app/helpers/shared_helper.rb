# frozen_string_literal: true

module SharedHelper
  def enterprise_user?
    spree_current_user&.enterprises&.count.to_i > 0
  end

  def admin_user?
    spree_current_user&.admin?
  end

  def current_shop_products_path
    "#{main_app.enterprise_shop_path(current_distributor)}#/shop_panel"
  end
end
