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
      record_type(DfcLoader.connector.PRODUCT_TYPES, product_type.to_s)
    end
  end

  def record_type(product_type_object, product_type)
    current_product_type = product_type_object.public_send(product_type.to_s)

    id = current_product_type.semanticId
    @product_types[id] = current_product_type

    # Narrower product types are defined as class method on the current product type object
    narrowers = current_product_type.methods(false).sort

    # Leaf node
    return if narrowers.empty?

    narrowers.each do |narrower|
      # recursive call
      record_type(current_product_type, narrower)
    end
  end
end
