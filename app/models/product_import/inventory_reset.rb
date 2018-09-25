module ProductImport
  class InventoryReset
    attr_reader :supplier_ids

    def initialize
      @supplier_ids = []
    end

    def <<(values)
      @supplier_ids << values
    end

    def reset(updated_ids, _supplier_ids)
      @updated_ids = updated_ids
      relation.update_all(count_on_hand: 0)
    end

    private

    attr_reader :updated_ids

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
