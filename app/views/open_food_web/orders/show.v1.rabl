object @order
attributes :id

node( :distributor ) { |p| p.distributor.blank? ? "" : p.distributor.name }
