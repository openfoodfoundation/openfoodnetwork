# frozen_string_literal: true

module PermittedAttributes
  class TagRules
    def self.attributes
      [
        :id, :type, :priority, :is_default, :preferred_customer_tags, :preferred_exchange_tags,
        :preferred_matched_order_cycles_visibility, :preferred_shipping_method_tags,
        :preferred_matched_shipping_methods_visibility, :preferred_payment_method_tags,
        :preferred_matched_payment_methods_visibility, :preferred_variant_tags,
        :preferred_matched_variants_visibility, :calculator_type,
        { calculator_attributes: [:id, :preferred_flat_percent] }
      ]
    end
  end
end
