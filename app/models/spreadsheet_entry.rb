# Class for defining spreadsheet entry objects for use in ProductImporter
class SpreadsheetEntry
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :line_number, :valid, :product_object, :product_validations, :save_type, :on_hand_nil

  attr_accessor :id, :product_id, :supplier, :supplier_id, :name, :display_name, :sku,
                :unit_value, :unit_description, :variant_unit, :variant_unit_scale, :variant_unit_name,
                :display_as, :category, :primary_taxon_id, :price, :on_hand, :on_demand,
                :tax_category_id, :shipping_category_id, :description

  def initialize(attrs)
    @product_validations = {}

    attrs.each do |k, v|
      if self.respond_to?("#{k}=")
        send("#{k}=", v) unless non_product_attributes.include?(k)
      else
        # Trying to assign unknown attribute. Record this and give feedback or just ignore silently?
      end
    end
  end

  def persisted?
    false #ActiveModel
  end

  def has_errors?
    self.errors.count > 0 or @product_validations.count > 0
  end

  def attributes
    attrs = {}
    self.instance_variables.each do |var|
      attrs[var.to_s.delete("@")] = self.instance_variable_get(var)
    end
    attrs.except(*non_product_attributes)
  end

  def displayable_attributes
    # Modified attributes list for displaying in user feedback
    attrs = {}
    self.instance_variables.each do |var|
      attrs[var.to_s.delete("@")] = self.instance_variable_get(var)
    end
    attrs.except(*non_product_attributes, *non_display_attributes)
  end

  def invalid_attributes
    invalid_attrs = {}
    @product_validations.messages.merge(self.errors.messages).each do |attr, message|
      invalid_attrs[attr.to_s] = "#{attr.to_s.capitalize} #{message.first}"
    end
    invalid_attrs.except(*non_product_attributes, *non_display_attributes)
  end

  private

  def non_display_attributes
    ['id', 'product_id', 'variant_id', 'supplier_id', 'primary_taxon', 'primary_taxon_id', 'category_id', 'shipping_category_id', 'tax_category_id']
  end

  def non_product_attributes
    ['line_number', 'valid', 'errors', 'product_object', 'product_validations', 'save_type', 'on_hand_nil']
  end
end
