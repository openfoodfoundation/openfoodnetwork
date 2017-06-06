object @order
attributes :id

node( :distributor ) { |p| p.distributor.blank? ? "" : p.distributor.name }
node( :line_items ) do |p|
  partial '/open_food_network/line_items/index', object: p.line_items
end
