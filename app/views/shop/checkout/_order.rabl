object current_order
attributes :id, :email, :shipping_method_id, :ship_address_same_as_billing

node :display_total do
  current_order.display_total.money.to_f
end

node :payment_method_id do
  current_order.payments.first.andand.payment_method_id
end

child current_order.bill_address => :bill_address do
  attributes :phone, :firstname, :lastname, :address1, :address2, :city, :country_id, :state_id, :zipcode
end

child current_order.ship_address => :ship_address do
  attributes :phone, :firstname, :lastname, :address1, :address2, :city, :country_id, :state_id, :zipcode
end

# Format here is {id: require_ship_address}
node :shipping_methods do
  Hash[current_order.distributor.shipping_methods.collect { 
    |method| [method.id, {
      require_ship_address: method.require_ship_address,
      price: method.compute_amount(current_order).to_f
    }] 
  }]
end
