require 'delegate'

module ProductImport
  class ResetAbsent < SimpleDelegator
    attr_reader :products_reset_count

    def initialize(decorated, settings)
      super(decorated)
      @products_reset_count = 0

      @settings = settings.settings
      @updated_ids = settings.updated_ids
      @enterprises_to_reset = settings.enterprises_to_reset
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # that were not listed in the newly uploaded spreadsheet
    def call
      return unless data_for_stock_reset?

      @suppliers_to_reset_products = []
      @suppliers_to_reset_inventories = []

      enterprises_to_reset.each do |enterprise_id|
        next unless reset_all_absent? && permission_by_id?(enterprise_id)

        if !importing_into_inventory?
          @suppliers_to_reset_products << enterprise_id.to_i
        end

        if importing_into_inventory?
          @suppliers_to_reset_inventories << enterprise_id.to_i
        end
      end

      unless @suppliers_to_reset_inventories.empty?
        relation = VariantOverride
          .where(
            'variant_overrides.hub_id IN (?) ' \
            'AND variant_overrides.id NOT IN (?)',
            @suppliers_to_reset_inventories,
            updated_ids
          )
        @products_reset_count += relation.update_all(count_on_hand: 0)
      end

      return if @suppliers_to_reset_products.empty?

      relation = Spree::Variant
        .joins(:product)
        .where(
          'spree_products.supplier_id IN (?) ' \
          'AND spree_variants.id NOT IN (?) ' \
          'AND spree_variants.is_master = false ' \
          'AND spree_variants.deleted_at IS NULL',
          @suppliers_to_reset_products,
          updated_ids
        )
      @products_reset_count += relation.update_all(count_on_hand: 0)
    end

    private

    attr_reader :settings, :updated_ids, :enterprises_to_reset

    def data_for_stock_reset?
      settings && updated_ids && enterprises_to_reset
    end

    def reset_all_absent?
      settings['reset_all_absent']
    end
  end
end
