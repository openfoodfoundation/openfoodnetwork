require 'delegate'

module ProductImport
  class ResetAbsent < SimpleDelegator
    attr_reader :products_reset_count

    def initialize(decorated, settings)
      super(decorated)
      @products_reset_count = 0

      @settings = settings

      @suppliers_to_reset_products = []
      @suppliers_to_reset_inventories = []
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # that were not listed in the newly uploaded spreadsheet
    def call
      settings.enterprises_to_reset.each do |enterprise_id|
        next unless permission_by_id?(enterprise_id)

        if importing_into_inventory?
          @suppliers_to_reset_inventories << enterprise_id.to_i
        else
          @suppliers_to_reset_products << enterprise_id.to_i
        end
      end

      if @suppliers_to_reset_inventories.present?
        relation = VariantOverride
          .where(
            'variant_overrides.hub_id IN (?) ' \
            'AND variant_overrides.id NOT IN (?)',
            @suppliers_to_reset_inventories,
            settings.updated_ids
          )
        @products_reset_count += relation.update_all(count_on_hand: 0)
        nil
      elsif @suppliers_to_reset_products.present?
        relation = Spree::Variant
          .joins(:product)
          .where(
            'spree_products.supplier_id IN (?) ' \
            'AND spree_variants.id NOT IN (?) ' \
            'AND spree_variants.is_master = false ' \
            'AND spree_variants.deleted_at IS NULL',
            @suppliers_to_reset_products,
            settings.updated_ids
          )
        @products_reset_count += relation.update_all(count_on_hand: 0)
      end
    end

    private

    attr_reader :settings
  end
end
