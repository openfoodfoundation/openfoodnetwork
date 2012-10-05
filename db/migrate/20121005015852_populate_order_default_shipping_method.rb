class PopulateOrderDefaultShippingMethod < ActiveRecord::Migration
  def up
    Spree::Order.where(shipping_method_id: nil).each do |order|
      order.send(:set_default_shipping_method)
    end
  end

  def down
  end
end
