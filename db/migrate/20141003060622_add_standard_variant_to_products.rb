class AddStandardVariantToProducts < ActiveRecord::Migration
  def up
    # Make sure that all products have a variant_unit
    Spree::Product.where("variant_unit IS NULL OR variant_unit = ''").update_all(variant_unit: "items", variant_unit_name: "each")

    # Find products without any standard variants
    products_with_only_master = Spree::Product.includes(:variants).where('spree_variants.id IS NULL').select('DISTINCT spree_products.*')

    products_with_only_master.each do |product|
      # Add a unit_value to the master variant if it doesn't have one
      if product.unit_value.blank?
        if product.variant_unit == "weight" && match = product.unit_description.andand.match(/^(\d+(\.\d*)?)(k?g) ?(.*)$/)
          scale = (match[3] == "kg" ? 1000 : 1)
          product.unit_value = (match[1].to_i*scale)
          product.unit_description = match[4]
          product.save!
        else
          unless product.variant_unit == "items" && product.unit_description.present?
            product.unit_value = 1
            product.save!
          end
        end
      end

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
      exchange_variants.update_all(variant_id: new_variant.id)
    end
  end
end
