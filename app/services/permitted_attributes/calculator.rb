# frozen_string_literal: true

module PermittedAttributes
  class Calculator
    def self.attributes
      [
        :id, :preferred_amount, :preferred_flat_percent,
        :preferred_minimal_amount, :preferred_normal_amount, :preferred_discount_amount,
        :preferred_unit_from_list, :preferred_per_unit, :preferred_first_item,
        :preferred_additional_item, :preferred_max_items
      ]
    end
  end
end
