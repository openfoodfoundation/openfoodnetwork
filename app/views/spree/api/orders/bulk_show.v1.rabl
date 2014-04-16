object @order
attributes :id, :number

node( :full_name ) { |order| order.billing_address.nil? ? "" : ( order.billing_address.full_name || "" ) }
node( :email ) { |order| order.email || "" }
node( :phone ) { |order| order.billing_address.nil? ? "a" : ( order.billing_address.phone || "" ) }
node( :completed_at ) { |order| order.completed_at.blank? ? "" : order.completed_at.strftime("%F %T") }
node( :distributor ) { |order| partial 'api/enterprises/bulk_show', :object => order.distributor }
node( :order_cycle ) { |order| partial 'api/order_cycles/bulk_show', :object => order.order_cycle }
node( :line_items ) do |order|
  order.line_items.order('id ASC').map do |line_item|
    partial 'spree/api/line_items/bulk_show', :object => line_item
  end
end