# frozen_string_literal: true

# Objects of this class represent a line from a spreadsheet that will be processed and used
# to create either product, variant, or inventory records. These objects are referred to as
# "entry" or "entries" throughout product import.

module ProductImport
  class SpreadsheetEntry
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_accessor :line_number, :valid, :validates_as, :product_object, :product_validations,
                  :on_hand_nil, :has_overrides, :units, :unscaled_units, :unit_type, :tax_category,
                  :shipping_category, :id, :product_id, :producer, :producer_id, :distributor,
                  :distributor_id, :name, :display_name, :sku, :unit_value, :unit_description,
                  :variant_unit, :variant_unit_scale, :variant_unit_name, :display_as, :category,
                  :primary_taxon_id, :price, :on_hand, :on_demand, :tax_category_id,
                  :shipping_category_id, :description, :import_date, :enterprise, :enterprise_id

    NON_DISPLAY_ATTRIBUTES = ['id', 'product_id', 'unscaled_units', 'variant_id', 'enterprise',
                              'enterprise_id', 'producer_id', 'distributor_id', 'primary_taxon',
                              'primary_taxon_id', 'category_id', 'shipping_category_id',
                              'tax_category_id', 'variant_unit_scale', 'variant_unit',
                              'unit_value'].freeze

    NON_PRODUCT_ATTRIBUTES = ['line_number', 'valid', 'errors', 'product_object',
                              'product_validations', 'inventory_validations', 'validates_as',
                              'save_type', 'on_hand_nil', 'has_overrides'].freeze

    NON_ASSIGNABLE_ATTRIBUTES = ['producer', 'producer_id', 'category', 'shipping_category',
                                 'tax_category', 'units', 'unscaled_units', 'unit_type',
                                 'enterprise', 'enterprise_id'].freeze

    def initialize(attrs)
      @validates_as = ''
      remove_empty_skus attrs
      assign_units attrs
    end

    def persisted?
      false # ActiveModel
    end

    def validates_as?(type)
      @validates_as == type
    end

    def errors?
      errors.count > 0 || @product_validations
    end

    def attributes
      attrs = {}
      instance_variables.each do |var|
        attrs[var.to_s.delete("@")] = instance_variable_get(var)
      end
      attrs.except(*NON_PRODUCT_ATTRIBUTES)
    end

    def assignable_attributes
      attributes.except(*NON_ASSIGNABLE_ATTRIBUTES)
    end

    def displayable_attributes
      # Modified attributes list for displaying in user feedback
      attrs = {}
      instance_variables.each do |var|
        attrs[var.to_s.delete("@")] = instance_variable_get(var)
      end
      attrs.except(*NON_PRODUCT_ATTRIBUTES, *NON_DISPLAY_ATTRIBUTES)
    end

    def invalid_attributes
      invalid_attrs = {}
      errors = if @product_validations
                 @product_validations.messages.merge(self.errors.messages)
               else
                 self.errors.messages
               end
      errors.each do |attr, message|
        invalid_attrs[attr.to_s] = "#{attr.to_s.capitalize} #{message.first}"
      end
      invalid_attrs.except(* NON_PRODUCT_ATTRIBUTES, *NON_DISPLAY_ATTRIBUTES)
    end

    def match_variant?(variant)
      match_display_name?(variant) && variant.unit_value.to_d == unit_value.to_d
    end

    private

    def remove_empty_skus(attrs)
      attrs.delete('sku') if attrs.key?('sku') && attrs['sku'].blank?
    end

    def assign_units(attrs)
      units = UnitConverter.new(attrs)

      units.converted_attributes.each do |attr, value|
        if respond_to?("#{attr}=") && NON_PRODUCT_ATTRIBUTES.exclude?(attr)
          public_send("#{attr}=", value)
        end
      end
    end

    def match_display_name?(variant)
      return true if display_name.blank? && variant.display_name.blank?

      variant.display_name == display_name
    end
  end
end
