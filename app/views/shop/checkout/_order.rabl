object current_order
attributes :id, :email

# Default to the first shipping method if none selected
# We don't want to do this on the order, BUT
# We can't set checked="checked" as Angular ignores it
# So we default the value in the JSON representation of the order
node :shipping_method_id do
  current_order.shipping_method_id || current_order.distributor.shipping_methods.first.andand.id
end

child current_order.bill_address => :bill_address do
  attributes :phone, :firstname, :lastname, :address1, :address2, :city, :country_id, :state_id, :zipcode
end

child current_order.ship_address => :ship_address do
  attributes :phone, :firstname, :lastname, :address1, :address2, :city, :country_id, :state_id, :zipcode
end

# Format here is {id: require_ship_address}
node :shipping_methods do
  Hash[current_order.distributor.shipping_methods.collect { |method| [method.id, method.require_ship_address] }]
end
