class AddStandardVariantToProducts < ActiveRecord::Migration
  def change
    # Find products without any standard variants
    products_with_only_master = Spree::Product.where( variants: [] )


    products_with_only_master.each do |product|
      # Run the callback to add a copy of the master variant as a standard variant
      product.send(:ensure_standard_variant)

      existing_master = product.master
      new_variant = product.variants.first

      # Replace any existing references to the master variant with the new standard variant

      # Option Values
      # Strategy: add all option values on existing_master to new_variant, and keep on existing_master
      option_values = existing_master.option_values
      option_values.each do |option_value|
        variant_ids = option_value.variant_ids
        variant_ids << new_variant.id
        option_value.update_attributes(variant_ids: variant_ids)
      end

      # Inventory Units
      # Strategy: completely replace all references to existing_master with new_variant
      inventory_units = existing_master.inventory_units
      inventory_units.each do |inventory_unit|
        inventory_unit.update_attributes(variant_id: new_variant.id )
      end

      # Line Items
      # Strategy: completely replace all references to existing_master with new_variant
      line_items = existing_master.line_items
      line_items.each do |line_item|
        line_item.update_attributes(variant_id: new_variant.id )
      end

      # Prices
      # Strategy: duplicate all prices on existing_master and assign them to new_variant
      prices = existing_master.prices
      new_prices = []
      prices.each do |price|
        new_prices << price.dup
      end
      new_variant.update_attributes(prices: new_prices)
    end
  end
end
