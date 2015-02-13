child distributed_taxons: :taxons do
  extends "json/taxon"
end
child suppliers: :producers do
  attributes :id
end
node :path do |enterprise|
  main_app.enterprise_shop_path(enterprise)
end
node :pickup do |hub|
  hub.shipping_methods.where(:require_ship_address => false).present?
end
node :delivery do |hub|
  hub.shipping_methods.where(:require_ship_address => true).present?
end
if @active_distributors
  node :active do |hub|
    @active_distributors.include?(hub)
  end
end
node :orders_close_at do |hub|
  OrderCycle.first_closing_for(hub).andand.orders_close_at
end
