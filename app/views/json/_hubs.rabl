collection Enterprise.visible.is_distributor
extends 'json/enterprises'

child distributed_taxons: :taxons do
  extends "json/taxon"
end

child suppliers: :producers do
  attributes :name, :id, :description, :long_description
  
  node :promo_image do |producer| 
    producer.promo_image.url 
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

node :hash do |hub|
  hub.to_param
end

node :active do |hub|
  @active_distributors.include?(hub)
end

node :orders_close_at do |hub|
  OrderCycle.first_closing_for(hub).andand.orders_close_at
end
