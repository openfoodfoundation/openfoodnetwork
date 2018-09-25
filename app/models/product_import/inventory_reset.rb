module ProductImport
  class InventoryReset
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
      VariantOverride.where(
        'variant_overrides.hub_id IN (?) ' \
        'AND variant_overrides.id NOT IN (?)',
        supplier_ids,
        updated_ids
      )
    end
  end
end
