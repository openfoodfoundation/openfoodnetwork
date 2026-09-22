# frozen_string_literal: true

# The current order's quantity and max_quantity (group buy) for one variant, to be used in the
# view. `max_quantity` is nil for a variant with no group buy max saved.
ViewData::CartItem = Data.define(:quantity, :max_quantity) do
  def self.empty
    new(quantity: 0, max_quantity: nil)
  end

  # A Hash of variant_id => ViewData::CartItem for the given line items, defaulting to .empty
  # for any variant not in the cart so callers can do `variants_in_cart[variant.id]` without a
  # nil check.
  def self.index(line_items)
    items = line_items.to_h do |li|
      [li.variant_id, new(quantity: li.quantity, max_quantity: li.max_quantity)]
    end

    Hash.new(empty).merge(items)
  end
end
