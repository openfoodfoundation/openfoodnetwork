object @cart
attributes :id

node( :orders ) do |p|
  partial '/open_food_network/orders/index', object: p.orders
end
