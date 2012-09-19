class AddShippingMethodToLineItems < ActiveRecord::Migration
  def up
    add_column :spree_line_items, :shipping_method_id, :integer

    Spree::LineItem.all.each do |li|
      begin
        shipping_method = li.product.shipping_method_for_distributor(li.order.distributor)
      rescue ArgumentError
        shipping_method = Spree::ShippingMethod.find_by_name 'Producer Delivery'
        say "Line item #{li.id} does not have a valid shipping method, setting to '#{shipping_method.name}'"
      end

      Spree::LineItem.update_all("shipping_method_id = #{shipping_method.id}", "id = #{li.id}")
    end
  end

  def down
    remove_column :spree_line_items, :shipping_method_id
  end
end
