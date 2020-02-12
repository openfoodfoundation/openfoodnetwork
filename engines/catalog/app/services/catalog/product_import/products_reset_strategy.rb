module ProductImport
  class ProductsResetStrategy
    def initialize(excluded_items_ids)
      @excluded_items_ids = excluded_items_ids
    end

    def reset(enterprise_ids)
      @enterprise_ids = enterprise_ids

      return 0 if enterprise_ids.blank?

      reset_variants_on_hand(enterprise_variants_relation)
    end

    private

    attr_reader :excluded_items_ids, :enterprise_ids

    def enterprise_variants_relation
      relation = Spree::Variant
        .joins(:product)
        .where(
          spree_products: { supplier_id: enterprise_ids },
          spree_variants: { is_master: false, deleted_at: nil }
        )

      return relation if excluded_items_ids.blank?

      relation.where('spree_variants.id NOT IN (?)', excluded_items_ids)
    end

    def reset_variants_on_hand(variants)
      updated_records_count = 0
      variants.each do |variant|
        updated_records_count += 1 if reset_variant_on_hand(variant)
      end
      updated_records_count
    end

    def reset_variant_on_hand(variant)
      variant.on_hand = 0
      variant.on_hand.zero?
    end
  end
end
