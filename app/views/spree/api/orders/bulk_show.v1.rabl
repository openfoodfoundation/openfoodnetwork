object @order
attributes :id, :email
node( :completed_at ) { |order| order.completed_at.blank? ? "" : order.completed_at.strftime("%F %T") }
node( :distributor ) { |order| partial 'spree/api/enterprises/bulk_show', :object => order.distributor }
node( :line_items ) do |order|
  order.line_items.order('id ASC').map do |line_item|
    partial 'spree/api/line_items/bulk_show', :object => line_item
  end
end