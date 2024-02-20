require "open_food_network/i18n_inflections"

class MigrateImportedVariantsData < ActiveRecord::Migration[7.0]
  class OptionValueNamer
    # nameable can be either a Spree::LineItem or a Spree::Variant
    def initialize(nameable = nil)
      @nameable = nameable
    end

    def name
      value, unit = option_value_value_unit
      separator = value_scaled? ? '' : ' '

      name_fields = []
      name_fields << "#{value}#{separator}#{unit}" if value.present? && unit.present?
      name_fields << @nameable.unit_description if @nameable.unit_description.present?
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
      @nameable.product.variant_unit_scale.present?
    end

    def option_value_value_unit
      if @nameable.unit_value.present? && @nameable.product&.persisted?
        if %w(weight volume).include? @nameable.product.variant_unit
          value, unit_name = option_value_value_unit_scaled
        else
          value = @nameable.unit_value
          unit_name = pluralize(@nameable.product.variant_unit_name, value)
        end

        value = value.to_i if value == value.to_i

      else
        value = unit_name = nil
      end

      [value, unit_name]
    end

    def option_value_value_unit_scaled
      unit_scale, unit_name = scale_for_unit_value

      value = (@nameable.unit_value / unit_scale).to_d.truncate(2)

      [value, unit_name]
    end

    def scale_for_unit_value
      WeightsAndMeasures.new(@nameable).scale_for_unit_value
    end

    def pluralize(unit_name, count)
      OpenFoodNetwork::I18nInflections.pluralize(unit_name, count)
    end
  end

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

      OptionValueNamer.new(self).name
    end
  end

  class Variant < ActiveRecord::Base
    include VariantAndLineItemNaming

    belongs_to :product

    self.table_name = "spree_variants"
  end

  class Product < ActiveRecord::Base
    has_many :variants

    self.table_name = "spree_products"
  end

  def up
    migrate_variant_unit

    Variant.where(unit_presentation: "").where.not(import_date: nil).each do |variant|
      variant.update_columns(
        variant.unit_value_attributes.merge(updated_at: Time.zone.now)
      )
    end
  end

  private

  def migrate_variant_unit
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET variant_unit = spree_products.variant_unit
      FROM spree_products
      WHERE spree_variants.product_id = spree_products.id
        AND spree_variants.variant_unit IS NULL
    SQL
    )
  end
end
