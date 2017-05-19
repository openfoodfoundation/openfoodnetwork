object current_order
attributes :id, :item_total

if current_order
  child line_items: :line_items do
    attributes :id, :variant_id, :quantity, :price 
  end

  node :cart_count do
    cart_count
  end
end
