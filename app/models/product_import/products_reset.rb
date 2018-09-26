module ProductImport
  class ProductsReset
    attr_reader :supplier_ids

    def initialize(excluded_items_ids)
      @supplier_ids = []
      @excluded_items_ids = excluded_items_ids
    end

    def <<(values)
      @supplier_ids << values
    end

    def reset
      relation.update_all(count_on_hand: 0)
    end

    private

    attr_reader :excluded_items_ids

    def relation
      relation = Spree::Variant
        .joins(:product)
        .where(
          spree_products: { supplier_id: supplier_ids },
          spree_variants: { is_master: false, deleted_at: nil }
        )

      return relation if excluded_items_ids.blank?

      relation.where('spree_variants.id NOT IN (?)', excluded_items_ids)
    end
  end
end
