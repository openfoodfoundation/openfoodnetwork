object current_order
attributes :id, :email, :shipping_method_id, :ship_address_same_as_billing

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
