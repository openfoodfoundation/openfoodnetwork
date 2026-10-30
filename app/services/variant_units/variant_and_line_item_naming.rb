# frozen_string_literal: true

# This module is included in both the Spree::Variant and Spree::LineItem model decorators
# It contains all of our logic for creating and naming option values (which are associated
# with both models) and methods for printing human readable "names" for instances of these models.

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

    def full_variant_name
      return variant_name if has_attribute?(:variant_name) && !variant_name.nil?
      return variant.full_name if respond_to?(:variant) && variant.present?

      full_name
    end

    def full_product_name
      return product_name if has_attribute?(:product_name) && !product_name.nil?

      product.name
    end

    def product_and_full_name
      return full_product_name if full_variant_name.blank?

      if full_variant_name.downcase.start_with?(full_product_name.downcase)
        full_variant_name
      else
        "#{full_product_name} - #{full_variant_name}"
      end
    end

    # Used like "product.name - full_name", preferably using product_and_full_name method above.
    # This returns, for a product with name "Bread":
    #     Bread - 1kg                     # if display_name blank
    #     Bread - Spelt Sourdough, 1kg    # if display_name is "Spelt Sourdough, 1kg"
    #     Bread - 1kg Spelt Sourdough     # if unit_to_display is "1kg Spelt Sourdough"
    # if display_name is "Spelt Sourdough" and unit_to_display is "1kg"
    #     Bread - Spelt Sourdough (1kg)
    def full_name
      display = display_name_for_naming
      return unit_to_display if display.blank?
      return display         if display.downcase.include? unit_to_display.downcase
      return unit_to_display if unit_to_display.downcase.include? display.downcase

      "#{display} (#{unit_to_display})"
    end

    def name_to_display
      if has_attribute?(:variant_display_name)
        return variant_display_name unless variant_display_name.nil?

        legacy_display_name = display_name_for_naming
        return legacy_display_name if legacy_display_name.present?

        return full_product_name
      end

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
      units.merge!(variant_unit:) if has_attribute?(:variant_unit)
      units.merge!(variant_unit_name: '') if reset_variant_unit_name?
      units
    end

    def weight_from_unit_value
      (unit_value || 0) / 1000 if variant_unit == 'weight'
    end

    private

    def display_name_for_naming
      if has_attribute?(:variant_display_name) && !variant_display_name.nil?
        variant_display_name
      elsif respond_to?(:display_name)
        display_name
      elsif respond_to?(:variant)
        variant&.display_name.to_s
      else
        ""
      end
    end

    def option_value_name
      return display_as if has_attribute?(:display_as) && display_as.present?

      VariantUnits::OptionValueNamer.new(self).name
    end

    def reset_variant_unit_name?
      has_attribute?(:variant_unit_name) && has_attribute?(:variant_unit) && variant_unit != 'items'
    end
  end
end
