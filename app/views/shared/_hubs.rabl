collection Enterprise.is_distributor
attributes :name, :id

child :address do
  attributes :city
  node :state do |address|
    address.state.abbr
  end
end

node :pickup do |hub|
  not hub.shipping_methods.where(:require_ship_address => false).empty?
end

node :delivery do |hub|
  not hub.shipping_methods.where(:require_ship_address => true).empty?
end

node :path do |hub|
  shop_enterprise_path(hub) 
end

#child :shipping_methods do
  #attributes :name, :require_ship_address
#end

# ALL PRODUCERS
#
# Orders closing when?
#   Current order_cycle + closing when?
