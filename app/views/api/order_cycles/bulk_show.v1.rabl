object @order_cycle

attributes :id, :name
node( :suppliers ) do |oc|
  partial 'api/enterprises/bulk_index', :object => oc.suppliers
end
node( :distributors ) do |oc|
  partial 'api/enterprises/bulk_index', :object => oc.distributors
end