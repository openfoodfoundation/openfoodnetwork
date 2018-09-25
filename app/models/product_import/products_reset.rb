module ProductImport
  class ProductsReset
    def initialize(updated_ids, supplier_ids)
      @updated_ids = updated_ids
      @supplier_ids = supplier_ids
    end

    def reset
      relation.update_all(count_on_hand: 0)
    end

    private

    attr_reader :updated_ids, :supplier_ids

    def relation
      Spree::Variant
        .joins(:product)
        .where(
          'spree_products.supplier_id IN (?) ' \
          'AND spree_variants.id NOT IN (?) ' \
          'AND spree_variants.is_master = false ' \
          'AND spree_variants.deleted_at IS NULL',
          supplier_ids,
          updated_ids
        )
    end
  end
end
