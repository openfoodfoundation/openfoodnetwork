require 'delegate'

module ProductImport
  class ResetAbsent < SimpleDelegator
    def call
      # For selected enterprises; set stock to zero for all products/inventory
      # that were not listed in the newly uploaded spreadsheet
      return unless data_for_stock_reset?
      suppliers_to_reset_products = []
      suppliers_to_reset_inventories = []

      settings = import_settings[:settings]

      import_settings[:enterprises_to_reset].each do |enterprise_id|
        if settings['reset_all_absent'] &&
           permission_by_id?(enterprise_id) &&
           !importing_into_inventory?
          suppliers_to_reset_products.push(Integer(enterprise_id))
        end

        if settings['reset_all_absent'] &&
           permission_by_id?(enterprise_id) &&
           importing_into_inventory?
          suppliers_to_reset_inventories.push(Integer(enterprise_id))
        end
      end

      unless suppliers_to_reset_inventories.empty?
        @products_reset_count += VariantOverride.
          where('variant_overrides.hub_id IN (?)
          AND variant_overrides.id NOT IN (?)', suppliers_to_reset_inventories, import_settings[:updated_ids]).
        update_all(count_on_hand: 0)
      end

      return if suppliers_to_reset_products.empty?

      @products_reset_count += Spree::Variant.joins(:product).
        where('spree_products.supplier_id IN (?)
        AND spree_variants.id NOT IN (?)
        AND spree_variants.is_master = false
        AND spree_variants.deleted_at IS NULL', suppliers_to_reset_products, import_settings[:updated_ids]).
      update_all(count_on_hand: 0)
    end

    private

    def data_for_stock_reset?
      import_settings[:settings] &&
        import_settings[:updated_ids] &&
        import_settings[:enterprises_to_reset]
    end
  end
end
