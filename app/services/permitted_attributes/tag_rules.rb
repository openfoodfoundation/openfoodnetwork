# frozen_string_literal: true

module PermittedAttributes
  class TagRules
    def self.attributes
      [
        :id, :type, :preferred_customer_tags, :calculator_type,
        { calculator_attributes: [:id, :preferred_flat_percent] }
      ]
    end
  end
end
