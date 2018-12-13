Spree::Stock::AvailabilityValidator.class_eval do
  def validate(line_item)
    # OFN specific check for in-memory :skip_stock_check attribute
    return if line_item.skip_stock_check

    quantity = adapt_line_item_quantity_to_inventory_units(line_item)
    return if quantity == 0

    validate_quantity(line_item, quantity)
  end

  private

  # This is an adapted version of a fix to the inventory_units not being considered here.
  # See #3090 for details.
  # This can be removed after upgrading to Spree 2.4.
  def adapt_line_item_quantity_to_inventory_units(line_item)
    shipment = line_item_shipment(line_item)
    return line_item.quantity unless shipment

    units = shipment.inventory_units_for(line_item.variant)
    line_item.quantity - units.count
  end

  def line_item_shipment(line_item)
    return line_item.target_shipment if line_item.target_shipment
    return line_item.order.shipments.first if line_item.order.present? && line_item.order.shipments.any?
  end

  # This is the spree v2.0.4 implementation of validate
  # But using the calculated quantity instead of the line_item.quantity.
  def validate_quantity(line_item, quantity)
    quantifier = Spree::Stock::Quantifier.new(line_item.variant_id)
    return if quantifier.can_supply? quantity

    variant = line_item.variant
    display_name = %Q{#{variant.name}}
    display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?
    line_item.errors[:quantity] << Spree.t(:out_of_stock, :scope => :order_populator, :item => display_name.inspect)
  end
end
