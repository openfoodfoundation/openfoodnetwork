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

    # Unimplemented measures
    #
    # The DFC knows lots of single piece measures like a tub. There are not
    # listed here and automatically mapped to "item". The following is a list
    # of measures we want or could implement.
    #
    # Length:
    #
    # :CENTIMETRE,
    # :DECIMETRE,
    # :METRE,
    # :KILOMETRE,
    # :INCH,
    #
    # Bundles:
    #
    # :_4PACK,
    # :_6PACK,
    # :DOZEN,
    # :HALFDOZEN,
    # :PAIR,
    #
    # Other:
    #
    # :PERCENT,
    measure, unit_name, unit_scale =
      case quantity.unit
      when quantity_unit.LITRE
        ["volume", "liter", 1]
      when quantity_unit.MILLILITRE
        ["volume", "ml", 0.001]
      when quantity_unit.CENTILITRE
        ["volume", "cl", 0.01]
      when quantity_unit.DECILITRE
        ["volume", "dl", 0.1]
      when quantity_unit.CUP
        # Interpreted as metric cup, not US legal cup.
        # https://github.com/datafoodconsortium/taxonomies/issues/8
        ["volume", "cu", 0.25]
      when quantity_unit.GALLON
        ["volume", "gal", 4.54609]
      when quantity_unit.MILLIGRAM
        ["weight", "mg", 0.001]
      when quantity_unit.GRAM
        ["weight", "gram", 1]
      when quantity_unit.KILOGRAM
        ["weight", "kg", 1_000]
      when quantity_unit.TONNE
        ["weight", "kg", 1_000_000]
      # Not part of the DFC yet:
      # when quantity_unit.OUNCE
      #   ["weight", "oz", 28.349523125]
      when quantity_unit.POUNDMASS
        ["weight", "lb", 453.59237]
      else
        ["items", "items", 1]
      end

    product.variant_unit = measure
    product.variant_unit_name = unit_name
    product.variant_unit_scale = unit_scale
    product.unit_value = quantity.value * unit_scale
  end
end
