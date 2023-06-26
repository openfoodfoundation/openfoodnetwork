# frozen_string_literal: true

# This module is included in both the Spree::Variant and Spree::LineItem model decorators
# It contains all of our logic for creating and naming option values (which are associated
# with both models) and methods for printing human readable "names" for instances of these models.

require 'variant_units/option_value_namer'

module VariantUnits
  module VariantAndLineItemNaming
    def options_text
      return unit_presentation unless variant_unit == "weight"
      return display_as if has_attribute?(:display_as) && display_as.present?
      return variant.display_as if variant_display_as?

      unit_presentation
    end

    def variant_display_as?
      respond_to?(:variant) && variant.present? &&
        variant.respond_to?(:display_as) && variant.display_as.present?
    end

    def product_and_full_name
      return product.name if full_name.blank?
      return "#{product.name} - #{full_name}" unless full_name.start_with?(product.name)

      full_name
    end

    # Used like "product.name - full_name", preferably using product_and_full_name method above.
    # This returns, for a product with name "Bread":
    #     Bread - 1kg                     # if display_name blank
    #     Bread - Spelt Sourdough, 1kg    # if display_name is "Spelt Sourdough, 1kg"
    #     Bread - 1kg Spelt Sourdough     # if unit_to_display is "1kg Spelt Sourdough"
    # if display_name is "Spelt Sourdough" and unit_to_display is "1kg"
    #     Bread - Spelt Sourdough (1kg)
    def full_name
      return unit_to_display if display_name.blank?
      return display_name    if display_name.downcase.include? unit_to_display.downcase
      return unit_to_display if unit_to_display.downcase.include? display_name.downcase

      "#{display_name} (#{unit_to_display})"
    end

    def name_to_display
      return product.name if display_name.blank?

      display_name
    end

    def unit_to_display
      return display_as if has_attribute?(:display_as) && display_as.present?
      return variant.display_as if variant_display_as?

      options_text.to_s
    end

    def assign_units
      assign_attributes(unit_value_attributes)
    end

    def update_units
      update_columns(unit_value_attributes)
    end

    def unit_value_attributes
      units = { unit_presentation: option_value_name }
      units.merge!(variant_unit: product.variant_unit) if has_attribute?(:variant_unit)
      units
    end

    def weight_from_unit_value
      (unit_value || 0) / 1000 if product.variant_unit == 'weight'
    end

    private

    def option_value_name
      return display_as if has_attribute?(:display_as) && display_as.present?

      VariantUnits::OptionValueNamer.new(self).name
    end
  end
end
