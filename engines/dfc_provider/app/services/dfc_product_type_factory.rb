# frozen_string_literal: true

require 'singleton'

class DfcProductTypeFactory
  include Singleton

  def self.for(dfc_id)
    instance.for(dfc_id)
  end

  def initialize
    @product_types = {}

    populate_product_types
  end

  def for(dfc_id)
    @product_types[dfc_id]
  end

  private

  def populate_product_types
    DfcLoader.connector.PRODUCT_TYPES.topConcepts.each do |product_type|
      stack = []
      record_type(stack, product_type.to_s)
    end
  end

  def record_type(stack, product_type)
    name = product_type.to_s
    current_stack = stack.dup.push(name)

    type = call_dfc_product_type(current_stack)

    id = type.semanticId
    @product_types[id] = type

    # Narrower product types are defined as class method on the current product type object
    narrowers = type.methods(false).sort

    # Leaf node
    return if narrowers.empty?

    narrowers.each do |narrower|
      # recursive call
      record_type(current_stack, narrower)
    end
  end

  # Callproduct type method ie: DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK
  def call_dfc_product_type(product_type_path)
    type = DfcLoader.connector.PRODUCT_TYPES
    product_type_path.each do |pt|
      type = type.public_send(pt)
    end

    type
  end
end
