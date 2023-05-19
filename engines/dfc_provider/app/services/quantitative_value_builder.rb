# frozen_string_literal: true

# Describes the quantity contained in a product, for example:
#
# - 1 piece of apple, usually meaning the whole fruit
# - 2 litres of milk, for example in a big bottle or pouch
# - 750 grams of bread, for example a loaf
#
# The DFC also supports specific units like loafs and cans but we don't have
# standardised data within OFN to map to these types.
class QuantitativeValueBuilder < DfcBuilder
  def self.quantity(variant)
    DataFoodConsortium::Connector::QuantitativeValue.new(
      unit: unit(variant),
      value: variant.unit_value,
    )
  end

  def self.unit(variant)
    case variant.product.variant_unit
    when "volume"
      DfcLoader.connector.MEASURES.UNIT.QUANTITYUNIT.LITRE
    when "weight"
      DfcLoader.connector.MEASURES.UNIT.QUANTITYUNIT.GRAM
    else
      DfcLoader.connector.MEASURES.UNIT.QUANTITYUNIT.PIECE
    end
  end
end
