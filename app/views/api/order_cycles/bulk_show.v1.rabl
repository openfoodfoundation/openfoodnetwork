object @order_cycle

attributes :id, :name
node( :suppliers ) do |oc|
  partial 'spree/api/enterprises/bulk_index', :object => oc.suppliers
end
node( :distributors ) do |oc|
  partial 'spree/api/enterprises/bulk_index', :object => oc.distributors
end