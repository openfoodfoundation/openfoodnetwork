#NOTE: when adding new fields for user input, it may want to be cached in localStorage
# If so, make sure to add it to controller attribute caching

object current_order
attributes :id, :email, :shipping_method_id, :user_id

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

# This is actually totally decoupled data and should be injected separately into their
# own services

node :shipping_methods do
  Hash[current_distributor.shipping_methods.uniq.collect { |method| 
    [method.id, {
      require_ship_address: method.require_ship_address,
      price: method.compute_amount(current_order).to_f,
      name: method.name,
      description: method.description
    }] 
  }]
end

node :payment_methods do
  Hash[current_order.available_payment_methods.collect { 
    |method| [method.id, {
      name: method.name,
      method_type: method.method_type
    }] 
  }]
end
