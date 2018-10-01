module ProductImport
  class InventoryResetStrategy
    attr_reader :supplier_ids

    def initialize(excluded_items_ids)
      @supplier_ids = []
      @excluded_items_ids = excluded_items_ids
    end

    def <<(values)
      @supplier_ids << values
    end

    def reset
      if supplier_ids.present?
        relation.update_all(count_on_hand: 0)
      else
        0
      end
    end

    private

    attr_reader :excluded_items_ids

    def relation
      relation = VariantOverride.where(hub_id: supplier_ids)
      return relation if excluded_items_ids.blank?

      relation.where('id NOT IN (?)', excluded_items_ids)
    end
  end
end
