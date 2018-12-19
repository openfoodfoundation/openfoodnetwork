# Report the stock levels of:
#   - all variants in the order
#   - all requested variant ids
class VariantsStockLevels
  def call(order, requested_variant_ids)
    variant_stock_levels = variant_stock_levels(order.line_items)

    li_variant_ids = variant_stock_levels.keys
    (requested_variant_ids - li_variant_ids).each do |variant_id|
      variant_on_hand = Spree::Variant.find(variant_id).on_hand
      variant_stock_levels[variant_id] = { quantity: 0, max_quantity: 0, on_hand: variant_on_hand }
    end

    variant_stock_levels
  end

  private

  def variant_stock_levels(line_items)
    Hash[
      line_items.map do |line_item|
        [line_item.variant.id,
          { quantity: line_item.quantity,
            max_quantity: line_item.max_quantity,
            on_hand: wrap_json_infinity(line_item.variant.on_hand) }]
      end
    ]
  end

  # Rails to_json encodes Float::INFINITY as Infinity, which is not valid JSON
  # Return it as a large integer (max 32 bit signed int)
  def wrap_json_infinity(number)
    number == Float::INFINITY ? 2147483647 : number
  end
end
