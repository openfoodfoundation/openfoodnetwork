# frozen_string_literal: true

class AddVariantFullName < ActiveRecord::Migration[7.0]
  class WeightsAndMeasures
    def initialize(variant)
      @variant = variant
      @units = UNITS
    end

    def scale_for_unit_value
      largest_unit = find_largest_unit(scales_for_variant_unit, system)
      return [nil, nil] unless largest_unit

      [largest_unit[0], largest_unit[1]["name"]]
    end

    def system
      return "custom" unless scales = scales_for_variant_unit
      return "custom" unless product_scale = @variant.product.variant_unit_scale

      scales[product_scale.to_f]['system']
    end

    private

    UNITS = {
      'weight' => {
        1.0 => { 'name' => 'g', 'system' => 'metric' },
        28.35 => { 'name' => 'oz', 'system' => 'imperial' },
        453.6 => { 'name' => 'lb', 'system' => 'imperial' },
        1000.0 => { 'name' => 'kg', 'system' => 'metric' },
        1_000_000.0 => { 'name' => 'T', 'system' => 'metric' }
      },
      'volume' => {
        0.001 => { 'name' => 'mL', 'system' => 'metric' },
        1.0 => { 'name' => 'L', 'system' => 'metric' },
        1000.0 => { 'name' => 'kL', 'system' => 'metric' }
      }
    }.freeze

    def scales_for_variant_unit
      @units[@variant.product.variant_unit]
    end

    # Find the largest available and compatible unit where unit_value comes
    #   to >= 1 when expressed in it.
    # If there is none available where this is true, use the smallest available unit.
    def find_largest_unit(scales, product_scale_system)
      return nil unless scales

      largest_unit = scales.select { |scale, unit_info|
        unit_info['system'] == product_scale_system &&
          @variant.unit_value / scale >= 1
      }.max
      return scales.first if largest_unit.nil?

      largest_unit
    end
  end


  module VariantUnits
    class OptionValueNamer
      def initialize(variant = nil)
        @variant = variant
      end

      def name(obj = nil)
        @variant = obj unless obj.nil?
        value, unit = option_value_value_unit
        separator = value_scaled? ? '' : ' '

        name_fields = []
        name_fields << "#{value}#{separator}#{unit}" if value.present? && unit.present?
        name_fields << @variant.unit_description if @variant.unit_description.present?
        name_fields.join ' '
      end

      def value
        value, = option_value_value_unit
        value
      end

      def unit
        _, unit = option_value_value_unit
        unit
      end

      private

      def value_scaled?
        @variant.product.variant_unit_scale.present?
      end

      def option_value_value_unit
        if @variant.unit_value.present?
          if %w(weight volume).include? @variant.product.variant_unit
            value, unit_name = option_value_value_unit_scaled
          else
            value = @variant.unit_value
            unit_name = pluralize(@variant.product.variant_unit_name, value)
          end

          value = value.to_i if value == value.to_i

        else
          value = unit_name = nil
        end

        [value, unit_name]
      end

      def option_value_value_unit_scaled
        unit_scale, unit_name = scale_for_unit_value

        value = (@variant.unit_value / unit_scale).to_d.truncate(2)

        [value, unit_name]
      end

      def scale_for_unit_value
        WeightsAndMeasures.new(@variant).scale_for_unit_value
      end

      def pluralize(unit_name, count)
        OpenFoodNetwork::I18nInflections.pluralize(unit_name, count)
      end
    end
  end

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
        return option_value.presentation unless option_value.option_type.name == "unit_weight"

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
      def generate_full_name
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
          option_values << ov # !
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

  module OpenFoodNetwork
    module I18nInflections
      # Make this a singleton to cache lookup tables.
      extend self

      def pluralize(word, count)
        return word if count.nil?

        key = i18n_key(word)

        return word unless key

        I18n.t(key, scope: "inflections", count: count, default: word)
      end

      private

      def i18n_key(word)
        @lookup ||= {}

        # The user may switch the locale. `I18n.t` is always using the current
        # locale and we need a lookup table for each of them.
        unless @lookup.key?(I18n.locale)
          @lookup[I18n.locale] = build_i18n_key_lookup
        end

        @lookup[I18n.locale][word.downcase]
      end

      def build_i18n_key_lookup
        lookup = {}
        I18n.t("inflections")&.each do |key, translations|
          translations.each_value do |translation|
            lookup[translation.downcase] = key
          end
        end
        lookup
      end
    end
  end

  module Spree
    class OptionValue < ActiveRecord::Base
      belongs_to :option_type, class_name: "Spree::OptionType"
      has_and_belongs_to_many :variants, join_table: 'spree_option_values_variants',
                              class_name: "Spree::Variant"

      self.table_name = "spree_option_values"
    end

    class OptionType < ApplicationRecord
      has_many :option_values, -> { order(:position) },
               class_name: "Spree::OptionValue", dependent: :destroy
      has_many :product_option_types, dependent: :destroy
      has_many :products, through: :product_option_types, class_name: "Spree::Product"

      default_scope -> { order("#{table_name}.position") }

      self.table_name = "spree_option_types"

      accepts_nested_attributes_for :option_values,
                                    reject_if: lambda { |ov|
                                      ov[:name].blank? || ov[:presentation].blank?
                                    },
                                    allow_destroy: true
    end

    class Product < ActiveRecord::Base
      include DelegateBelongsTo

      self.table_name = "spree_products"

      has_many :variants, class_name: "Spree::Variant"
      has_many :product_option_types, dependent: :destroy
      has_many :option_types, through: :product_option_types, class_name: "Spree::OptionType", dependent: :destroy
    end

    class Variant < ActiveRecord::Base
      include DelegateBelongsTo
      include VariantUnits::VariantAndLineItemNaming

      self.table_name = "spree_variants"

      belongs_to :product, class_name: "Spree::Product"
      has_and_belongs_to_many :option_values, class_name: "Spree::OptionValue",
                              join_table: :spree_option_values_variants

      delegate_belongs_to :product, :name, :description
    end
  end

  def up
    add_column :spree_variants, :full_name, :string

    Spree::Variant.includes(option_values: :option_type).find_in_batches do |batch|
      batch.each{|variant| variant.update_columns(full_name: variant.generate_full_name) }
    end
  end

  def down
    remove_column :spree_variants, :full_name
  end
end
