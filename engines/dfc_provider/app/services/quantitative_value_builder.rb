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
      unit: unit(variant.variant_unit),
      value: variant.unit_value,
    )
  end

  def self.unit(unit_name)
    case unit_name
    when "volume"
      DfcLoader.connector.MEASURES.LITRE
    when "weight"
      DfcLoader.connector.MEASURES.GRAM
    else
      DfcLoader.connector.MEASURES.PIECE
    end
  end

  def self.apply(quantity, variant)
    measure, unit_name, unit_scale = map_unit(quantity.unit)
    value = quantity.value.to_f * unit_scale

    # Import invalid value as one item.
    if measure.in?(%w(weight volume)) && value <= 0
      measure = "items"
      unit_name = "items"
      value = 1
    end

    # Items don't have a scale, only a value on the variant.
    unit_scale = nil if measure == "items"

    variant.variant_unit = measure
    variant.variant_unit_name = unit_name if measure == "items"
    variant.variant_unit_scale = unit_scale
    variant.unit_value = value
  end

  # Map DFC units to OFN fields:
  #
  # - variant_unit
  # - variant_unit_name
  # - variant_unit_scale
  #
  # Unimplemented measures
  #
  # The DFC knows lots of single piece measures like a tub. There are not
  # listed here and automatically mapped to "item". The following is a list
  # of measures we want or could implement.
  #
  # Length is not represented in the OFN:
  #
  # :CENTIMETRE,
  # :DECIMETRE,
  # :METRE,
  # :KILOMETRE,
  # :INCH,
  #
  # Other:
  #
  # :PERCENT,
  #
  # This method is quite long and may be shortened with new DFC features:
  #
  # * https://github.com/datafoodconsortium/taxonomies/issues/7
  # * https://github.com/datafoodconsortium/connector-ruby/issues/18
  #
  # Until then, we can ignore Rubocop metrics, IMO.
  def self.map_unit(unit) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    quantity_unit = DfcLoader.connector.MEASURES

    # The unit name is only set for items. The name is implied for weight and
    # volume and filled in by `WeightsAndMeasures`.
    case unit
    when quantity_unit.LITRE
      ["volume", nil, 1]
    when quantity_unit.MILLILITRE
      ["volume", nil, 0.001]
    when quantity_unit.CENTILITRE
      ["volume", nil, 0.01]
    when quantity_unit.DECILITRE
      ["volume", nil, 0.1]
    when quantity_unit.GALLON
      ["volume", nil, 4.54609]

    when quantity_unit.MILLIGRAM
      ["weight", nil, 0.001]
    when quantity_unit.GRAM
      ["weight", nil, 1]
    when quantity_unit.KILOGRAM
      ["weight", nil, 1_000]
    when quantity_unit.TONNE
      ["weight", nil, 1_000_000]
    # Not part of the DFC yet:
    # when quantity_unit.OUNCE
    #   ["weight", nil, 28.349523125]
    when quantity_unit.POUNDMASS
      ["weight", nil, 453.59237]

    when quantity_unit.PAIR
      ["items", "pair", 2]
    when quantity_unit._4PACK
      ["items", "4 pack", 4]
    when quantity_unit._6PACK
      ["items", "6 pack", 6]
    when quantity_unit.HALFDOZEN
      ["items", "half dozen", 6]
    when quantity_unit.DOZEN
      ["items", "dozen", 12]
    else
      # Labels may be provided one day:
      # https://github.com/datafoodconsortium/connector-ruby/issues/18
      unit_id = unit.try(:semanticId)&.split("#")&.last&.split(":")&.last
      label = unit_id || "items"
      ["items", label, 1]
    end
  end
end
