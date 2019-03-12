# Report the stock levels of:
#   - all variants in the order
#   - all requested variant ids
class VariantsStockLevels
  def call(order, requested_variant_ids)
    variant_stock_levels = variant_stock_levels(order.line_items)

    # Variants are not scoped here and so the stock levels reported are incorrect
    # See cart_controller_spec for more details and #3222
    order_variant_ids = variant_stock_levels.keys
    missing_variant_ids = requested_variant_ids - order_variant_ids
    missing_variant_ids.each do |variant_id|
      variant = Spree::Variant.find(variant_id)
      variant_stock_levels[variant_id] = { quantity: 0, max_quantity: 0, on_hand: variant.on_hand, on_demand: variant.on_demand }
    end

    # The code above is most probably dead code, this bugsnag notification will confirm it
    notify_bugsnag(order, requested_variant_ids, order_variant_ids) if missing_variant_ids.present?

    variant_stock_levels
  end

  private

  def notify_bugsnag(order, requested_variant_ids, order_variant_ids)
    error_msg = "VariantsStockLevels.call with variants in the request that are not in the order"
    Bugsnag.notify(RuntimeError.new(error_msg),
                   requested_variant_ids: requested_variant_ids.as_json,
                   order_variant_ids: order_variant_ids.as_json,
                   order: order.as_json,
                   line_items: order.line_items.as_json)
  end

  def variant_stock_levels(line_items)
    Hash[
      line_items.map do |line_item|
        [line_item.variant.id,
         { quantity: line_item.quantity,
           max_quantity: line_item.max_quantity,
           on_hand: line_item.variant.on_hand,
           on_demand: line_item.variant.on_demand }]
      end
    ]
  end
end
