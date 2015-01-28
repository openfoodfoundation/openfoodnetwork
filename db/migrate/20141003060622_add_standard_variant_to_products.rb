class AddStandardVariantToProducts < ActiveRecord::Migration
  def up
    # Find products without any standard variants
    products_with_only_master = Spree::Product.find(:all, :include => "variants", :conditions => ["spree_variants.id IS NULL"])

    products_with_only_master.each do |product|
      # Run the callback to add a copy of the master variant as a standard variant
      product.send(:ensure_standard_variant)

      existing_master = product.master
      new_variant = product.variants.first

      # Replace any relevant references to the master variant with the new standard variant

      # Inventory Units
      # Strategy: do nothing to inventory units pertaining to existing_master,
      # new inventory units will be created with reference to new_variant

      # Line Items
      # Strategy: do nothing to line items pertaining to existing_master,
      # new line items will be created with reference to new_variant

      # Option Values
      # Strategy: add all option values on existing_master to new_variant, and keep on existing_master
      option_values = existing_master.option_values
      option_values.each do |option_value|
        variant_ids = option_value.variant_ids
        variant_ids << new_variant.id
        option_value.update_attributes(variant_ids: variant_ids)
      end

      # Prices
      # Strategy: duplicate all prices on existing_master and assign them to new_variant
      existing_prices = existing_master.prices
      existing_prices.each do |price|
        new_variant.prices << price.dup
      end

      # Exchange Variants
      # Strategy: Replace all references to existing master in exchanges with new_variant
      exchange_variants = ExchangeVariant.where(variant_id: existing_master.id)
      exchange_variants.each do |exchange_variant|
        exchange_variant.update_attributes(variant_id: new_variant.id )
      end
    end
  end
end
