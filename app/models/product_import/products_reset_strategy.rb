module ProductImport
  class ProductsResetStrategy
    def initialize(excluded_items_ids)
      @excluded_items_ids = excluded_items_ids
    end

    def reset(supplier_ids)
      @supplier_ids = supplier_ids

      if supplier_ids.present?
        relation.update_all(count_on_hand: 0)
      else
        0
      end
    end

    private

    attr_reader :excluded_items_ids, :supplier_ids

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
