class UpdateLineItemCaching < ActiveRecord::Migration

  class SpreeLineItem < ActiveRecord::Base
    belongs_to :shipping_method, class_name: 'Spree::ShippingMethod'
    belongs_to :variant, :class_name => "Spree::Variant"

    def itemwise_shipping_cost
      order = OpenStruct.new :line_items => [self]
      shipping_method.compute_amount(order)
    end

    def amount
      price * quantity
    end
    alias total amount
  end


  def up
    add_column :spree_line_items, :distribution_fee, :decimal, precision: 10, scale: 2
    add_column :spree_line_items, :shipping_method_name, :string

    SpreeLineItem.all.each do |line_item|
      line_item.update_column(:distribution_fee, line_item.itemwise_shipping_cost)
      line_item.update_column(:shipping_method_name, line_item.shipping_method.name)
    end

    remove_column :spree_line_items, :shipping_method_id
  end

  def down
    add_column :spree_line_items, :shipping_method_id, :integer

    SpreeLineItem.all.each do |line_item|
      shipping_method = Spree::ShippingMethod.find_by_name(line_item.shipping_method_name)
      unless shipping_method
        say "Shipping method #{line_item.shipping_method_name} not found, using the first available shipping method for LineItem #{line_item.id}"
        shipping_method = Spree::ShippingMethod.where("name != 'Delivery'").first
      end

      line_item.update_column(:shipping_method_id, shipping_method.id)
    end

    remove_column :spree_line_items, :distribution_fee
    remove_column :spree_line_items, :shipping_method_name
  end
end
