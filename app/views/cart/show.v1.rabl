object @cart
attributes :id

node( :orders ) do |p|
  partial '/orders/index', object: p.orders
end
