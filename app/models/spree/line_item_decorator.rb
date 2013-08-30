Spree::LineItem.class_eval do
  attr_accessible :max_quantity

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      # User has a distributor on the Order or supplier that supplies a LineItem
      joins('LEFT OUTER JOIN spree_variants ON (spree_variants.id = spree_line_items.variant_id)').
      joins('LEFT OUTER JOIN spree_products ON (spree_products.id = spree_variants.product_id)').
      joins(:order).
      where('spree_orders.distributor_id IN (?) OR spree_products.supplier_id IN (?)', user.enterprises, user.enterprises).
      select('spree_line_items.*')
    end
  }
end
