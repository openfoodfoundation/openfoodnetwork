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

  def self.apply(quantity, product)
    quantity_unit = DfcLoader.connector.MEASURES.UNIT.QUANTITYUNIT

    measure, unit_name, unit_scale =
      case quantity.unit
      when quantity_unit.LITRE
        ["volume", "liter", 1]
      when quantity_unit.GRAM
        ["weight", "gram", 1]
      when quantity_unit.KILOGRAM
        ["weight", "kg", 1_000]
      else
        ["items", "items", 1]
      end

    product.variant_unit = measure
    product.variant_unit_name = unit_name
    product.variant_unit_scale = unit_scale
    product.unit_value = quantity.value * unit_scale
  end
end
