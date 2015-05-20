object @order_cycle

attributes :id, :name
node( :first_order ) { |order| order.orders_open_at.strftime("%F") }
node( :last_order ) { |order| (order.orders_close_at + 1.day).strftime("%F") }
node( :suppliers ) do |oc|
  partial 'api/enterprises/bulk_index', :object => oc.suppliers
end
node( :distributors ) do |oc|
  partial 'api/enterprises/bulk_index', :object => oc.distributors
end
