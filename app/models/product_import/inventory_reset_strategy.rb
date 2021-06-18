# frozen_string_literal: true

module ProductImport
  class InventoryResetStrategy
    def initialize(excluded_items_ids)
      @excluded_items_ids = excluded_items_ids
    end

    def reset(enterprise_ids)
      @enterprise_ids = enterprise_ids

      if enterprise_ids.present?
        relation.update_all(count_on_hand: 0, on_demand: false)
      else
        0
      end
    end

    private

    attr_reader :excluded_items_ids, :enterprise_ids

    def relation
      relation = VariantOverride.where(hub_id: enterprise_ids)
      return relation if excluded_items_ids.blank?

      relation.where('id NOT IN (?)', excluded_items_ids)
    end
  end
end
