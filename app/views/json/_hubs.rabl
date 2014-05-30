collection Enterprise.visible.is_distributor
extends 'json/enterprises'

child distributed_taxons: :taxons do
  extends "json/taxon"
end

child suppliers: :producers do
  extends "json/producer"
end

node :pickup do |hub|
  not hub.shipping_methods.where(:require_ship_address => false).empty?
end

node :delivery do |hub|
  not hub.shipping_methods.where(:require_ship_address => true).empty?
end

node :active do |hub|
  @active_distributors.include?(hub)
end

node :orders_close_at do |hub|
  OrderCycle.first_closing_for(hub).andand.orders_close_at
end
