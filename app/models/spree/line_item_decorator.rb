Spree::LineItem.class_eval do
  attr_accessible :max_quantity

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      # Find line items that are from orders distributed by the user or supplied by the user
      joins(:variant => :product).
      joins(:order).
      where('spree_orders.distributor_id IN (?) OR spree_products.supplier_id IN (?)', user.enterprises, user.enterprises).
      select('spree_line_items.*')
    end
  }

  scope :supplied_by, lambda { |enterprise|
    joins(:product).
    where('spree_products.supplier_id = ?', enterprise)
  }
  scope :supplied_by_any, lambda { |enterprises|
    joins(:product).
    where('spree_products.supplier_id IN (?)', enterprises)
  }

  def amount_with_adjustments
    # EnterpriseFee#create_locked_adjustment applies adjustments on line items to their parent order,
    # so line_item.adjustments returns an empty array
    amount + Spree::Adjustment.where(source_id: id).sum(&:amount)
  end

  def display_amount_with_adjustments
    Spree::Money.new(amount_with_adjustments, { :currency => currency })
  end
end
