# frozen_string_literal: true

# This module is included in both the Spree::Variant and Spree::LineItem model decorators
# It contains all of our logic for creating and naming option values (which are associated
# with both models) and methods for printing human readable "names" for instances of these models.

require 'variant_units/option_value_namer'

module VariantUnits
  module VariantAndLineItemNaming
    # Copied and modified from Spree::Variant
    def options_text
      values = if option_values_eager_loaded?
                 # Don't trigger N+1 queries if option_values are already eager-loaded.
                 # For best results, use: `Spree::Variant.includes(option_values: :option_type)`
                 # or: `Spree::Product.includes(variant: {option_values: :option_type})`
                 option_values.sort_by{ |o| o.option_type.position }
               else
                 option_values.joins(:option_type).
                   order("#{Spree::OptionType.table_name}.position asc")
               end

      values.map { |option_value|
        presentation(option_value)
      }.to_sentence(words_connector: ", ", two_words_connector: ", ")
    end

    def presentation(option_value)
      return display_as if has_attribute?(:display_as) && display_as.present?
      return variant.display_as if variant_display_as?

      option_value.presentation
    end

    def variant_display_as?
      respond_to?(:variant) && variant.present? &&
        variant.respond_to?(:display_as) && variant.display_as.present?
    end

    def product_and_full_name
      return "#{product.name} - #{full_name}" unless full_name.start_with? product.name

      full_name
    end

    # Used like "product.name - full_name", preferably using product_and_full_name method above.
    # This returns, for a product with name "Bread":
    #     Bread - 1kg                     # if display_name blank
    #     Bread - Spelt Sourdough, 1kg    # if display_name is "Spelt Sourdough, 1kg"
    #     Bread - 1kg Spelt Sourdough     # if unit_to_display is "1kg Spelt Sourdough"
    #     Bread - Spelt Sourdough (1kg)   # if display_name is "Spelt Sourdough" and unit_to_display is "1kg"
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

      options_text
    end

    def update_units
      delete_unit_option_values

      option_type = product.variant_unit_option_type
      if option_type
        name = option_value_name
        ov = Spree::OptionValue.where(option_type_id: option_type, name: name,
                                      presentation: name).first ||
             Spree::OptionValue.create!(option_type: option_type, name: name, presentation: name)
        option_values << ov
      end
    end

    def delete_unit_option_values
      ovs = option_values.where(option_type_id: Spree::Product.all_variant_unit_option_types)
      option_values.destroy ovs
    end

    def weight_from_unit_value
      (unit_value || 0) / 1000 if product.variant_unit == 'weight'
    end

    private

    def option_values_eager_loaded?
      option_values.loaded?
    end

    def option_value_name
      if has_attribute?(:display_as) && display_as.present?
        display_as
      else
        option_value_namer = VariantUnits::OptionValueNamer.new self
        option_value_namer.name
      end
    end
  end
end
