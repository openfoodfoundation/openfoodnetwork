object @cart
attributes :id

node( :orders ) do |p|
  partial '/open_food_web/orders/index', object: p.orders
end
