# frozen_string_literal: true

# Translates the order lines of a DFC order into OFN line item attributes.
class OrderLineItemsBuilder < DfcBuilder
  # Returns the nested attributes to apply, the ids of line items that are no
  # longer part of the order, and the semantic ids of any products we couldn't
  # recognise.
  def self.attributes(ofn_order, dfc_order, variant_scope)
    incoming, unknown = incoming_quantities(dfc_order, variant_scope)
    attrs, stale_ids = reconcile(ofn_order, incoming)

    [attrs, stale_ids, unknown]
  end

  def self.incoming_quantities(dfc_order, variant_scope)
    quantities = {}
    unknown = []

    dfc_order.lines.each do |line|
      next if line.quantity.nil? || line.quantity <= 0
      next if line.offer&.offeredItem.nil?

      product_id = extract_semantic_id(line.offer.offeredItem)
      variant = find_variant(product_id, variant_scope)

      if variant
        # The same product may be ordered in several lines.
        quantities[variant.id] = quantities[variant.id].to_i + line.quantity
      else
        unknown << product_id
      end
    end

    [quantities, unknown]
  end

  # The offered item has to be a product of the enterprise the order is placed
  # with. We can't take an arbitrary variant id from the payload.
  def self.find_variant(product_id, variant_scope)
    id = product_id[%r{/supplied_products/(\d+)\z}, 1]

    variant_scope.find_by(id:) if id
  end

  def self.reconcile(ofn_order, incoming)
    attrs = []
    stale_ids = []

    ofn_order.line_items.each do |line_item|
      if incoming.key?(line_item.variant_id)
        attrs << { id: line_item.id, quantity: incoming.delete(line_item.variant_id) }
      else
        stale_ids << line_item.id
      end
    end

    incoming.each do |variant_id, quantity|
      attrs << { variant_id:, quantity: }
    end

    [attrs, stale_ids]
  end

  private_class_method :incoming_quantities, :find_variant, :reconcile
end
