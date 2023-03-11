# frozen_string_literal: true

# This class handles a number of custom validation processes that take place during product import,
# as a spreadsheet entry is checked to see if it is a valid product, variant, or inventory item.
# It also handles error messages and user feedback for the validation process.

module ProductImport
  class EntryValidator
    SKIP_VALIDATE_ON_UPDATE = [:description].freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(current_user, import_time, spreadsheet_data, editable_enterprises,
                   inventory_permissions, reset_counts, import_settings, all_entries)
      @current_user = current_user
      @import_time = import_time
      @spreadsheet_data = spreadsheet_data
      @editable_enterprises = editable_enterprises
      @inventory_permissions = inventory_permissions
      @reset_counts = reset_counts
      @import_settings = import_settings
      @all_entries = all_entries
    end
    # rubocop:enable Metrics/ParameterLists

    def self.non_updatable_fields
      {
        category: :primary_taxon_id,
        description: :description,
        unit_type: :variant_unit_scale,
        variant_unit_name: :variant_unit_name,
        tax_category: :tax_category_id,
        shipping_category: :shipping_category_id
      }
    end

    def validate_all(entries)
      entries.each do |entry|
        assign_enterprise_field(entry)
        enterprise_validation(entry)
        unit_fields_validation(entry)
        variant_of_product_validation(entry)

        next if entry.enterprise_id.blank?

        if import_into_inventory?
          producer_validation(entry)
          inventory_validation(entry)
        else
          category_validation(entry)
          tax_and_shipping_validation(entry, 'tax', entry.tax_category, @spreadsheet_data.tax_index)
          tax_and_shipping_validation(entry,
                                      'shipping',
                                      entry.shipping_category,
                                      @spreadsheet_data.shipping_index)
          shipping_presence_validation(entry)
          product_validation(entry)
        end
      end
    end

    def assign_enterprise_field(entry)
      entry.enterprise = entry.public_send(enterprise_field)
    end

    def enterprise_field
      import_into_inventory? ? :distributor : :producer
    end

    def mark_as_new_variant(entry, product_id)
      new_variant = Spree::Variant.new(
        entry.assignable_attributes.except('id', 'product_id', 'on_hand', 'on_demand',
                                           'variant_unit', 'variant_unit_name',
                                           'variant_unit_scale', 'primary_taxon_id')
      )
      new_variant.save
      if new_variant.persisted?
        if entry.attributes['on_demand'].present?
          new_variant.on_demand = entry.attributes['on_demand']
        end
        if entry.attributes['on_hand'].present?
          new_variant.on_hand = entry.attributes['on_hand']
        end
      end

      new_variant.product_id = product_id
      check_on_hand_nil(entry, new_variant)

      if new_variant.valid?
        entry.product_object = new_variant
        entry.validates_as = 'new_variant' unless entry.errors?
      else
        mark_as_invalid(entry, product_validations: new_variant.errors)
      end
    end

    private

    def find_or_initialize_variant_override(entry, existing_variant)
      existing_variant_override = VariantOverride.where(
        variant_id: existing_variant.id,
        hub_id: entry.enterprise_id
      ).first

      existing_variant_override || VariantOverride.new(
        variant_id: existing_variant.id,
        hub_id: entry.enterprise_id
      )
    end

    def enterprise_validation(entry)
      return if name_presence_error entry
      return if enterprise_not_found_error entry
      return if permissions_error entry
      return if primary_producer_error entry

      entry.enterprise_id =
        @spreadsheet_data.enterprises_index[entry.enterprise][:id]

      entry.public_send(
        "#{enterprise_field}_id=",
        @spreadsheet_data.enterprises_index[entry.enterprise][:id]
      )
    end

    def name_presence_error(entry)
      return if entry.enterprise.present?

      mark_as_invalid(entry,
                      attribute: enterprise_field,
                      error: I18n.t(:error_required))
      true
    end

    def enterprise_not_found_error(entry)
      return if @spreadsheet_data.enterprises_index[entry.enterprise][:id]

      mark_as_invalid(entry,
                      attribute: enterprise_field,
                      error: I18n.t(:error_not_found_in_database,
                                    name: entry.enterprise))
      true
    end

    def permissions_error(entry)
      return if permission_by_name?(entry.enterprise)

      mark_as_invalid(entry,
                      attribute: enterprise_field,
                      error: I18n.t(:error_no_permission_for_enterprise,
                                    name: entry.enterprise))
      true
    end

    def primary_producer_error(entry)
      return if import_into_inventory?
      return if @spreadsheet_data.enterprises_index[entry.enterprise][:is_primary_producer]

      mark_as_invalid(entry,
                      attribute: enterprise_field,
                      error: I18n.t(:error_not_primary_producer,
                                    name: entry.enterprise))
      true
    end

    def unit_fields_validation(entry)
      unit_types = ['g', 'oz', 'lb', 'kg', 't', 'ml', 'l', 'kl', '']

      unless entry.units&.present?
        mark_as_invalid(entry, attribute: 'units',
                               error: I18n.t('admin.product_import.model.blank'))
      end

      return if import_into_inventory?

      # unit_type must be valid type
      if entry.unit_type&.present?
        unit_type = entry.unit_type.to_s.strip.downcase
        unless unit_types.include?(unit_type)
          mark_as_invalid(entry, attribute: 'unit_type',
                                 error: I18n.t('admin.product_import.model.incorrect_value'))
        end
        return
      end

      # variant_unit_name must be present if unit_type not present
      return if entry.variant_unit_name&.present?

      mark_as_invalid(entry, attribute: 'variant_unit_name',
                             error: I18n.t('admin.product_import.model.conditional_blank'))
    end

    def variant_of_product_validation(entry)
      return if entry.producer.blank? || entry.name.blank?

      validate_unit_type_unchanged(entry)
      validate_variant_unit_name_unchanged(entry)
    end

    def validate_unit_type_unchanged(entry)
      return if entry.unit_type.blank?

      reference_entry = all_entries_for_product(entry).first
      return if entry.unit_type.to_s == reference_entry.unit_type.to_s

      mark_as_not_updatable(entry, "unit_type")
    end

    def validate_variant_unit_name_unchanged(entry)
      return if entry.variant_unit_name.blank?

      reference_entry = all_entries_for_product(entry).first
      return if entry.variant_unit_name.to_s == reference_entry.variant_unit_name.to_s

      mark_as_values_must_be_same(entry, "variant_unit_name")
    end

    def producer_validation(entry)
      producer_name = entry.producer

      if producer_name.blank?
        mark_as_invalid(entry, attribute: "producer",
                               error: I18n.t('admin.product_import.model.blank'))
        return
      end

      unless @spreadsheet_data.producers_index[producer_name]
        model_not_found = I18n.t('admin.product_import.model.not_found')
        mark_as_invalid(entry, attribute: "producer",
                               error: "\"#{producer_name}\" #{model_not_found}")
        return
      end

      unless inventory_permission?(
        entry.enterprise_id,
        @spreadsheet_data.producers_index[producer_name]
      )

        inventory_no_permission = I18n.t('admin.product_import.model.inventory_no_permission')
        mark_as_invalid(entry, attribute: "producer",
                               error: "\"#{producer_name}\": #{inventory_no_permission}")
        return
      end

      entry.producer_id = @spreadsheet_data.producers_index[producer_name]
    end

    def inventory_validation(entry)
      products = Spree::Product.where(supplier_id: entry.producer_id,
                                      name: entry.name,
                                      deleted_at: nil)

      if products.empty?
        mark_as_invalid(entry, attribute: 'name',
                               error: I18n.t('admin.product_import.model.no_product'))
        return
      end

      products.flat_map(&:variants).each do |existing_variant|
        unit_scale = existing_variant.product.variant_unit_scale
        unscaled_units = entry.unscaled_units.to_f || 0
        entry.unit_value = unscaled_units * unit_scale unless unit_scale.nil?

        if entry_matches_existing_variant?(entry, existing_variant)
          variant_override = create_inventory_item(entry, existing_variant)
          return validate_inventory_item(entry, variant_override)
        end
      end

      mark_as_invalid(entry, attribute: 'product',
                             error: I18n.t('admin.product_import.model.not_found'))
    end

    def entry_matches_existing_variant?(entry, existing_variant)
      display_name_are_the_same?(entry, existing_variant) &&
        existing_variant.unit_value == entry.unit_value.to_f
    end

    def display_name_are_the_same?(entry, existing_variant)
      return true if entry.display_name.blank? && existing_variant.display_name.blank?

      existing_variant.display_name == entry.display_name
    end

    def category_validation(entry)
      category_name = entry.category

      if category_name.blank?
        mark_as_invalid(entry, attribute: "category", error: I18n.t(:error_required))
        return
      end

      if @spreadsheet_data.categories_index[category_name]
        entry.primary_taxon_id = @spreadsheet_data.categories_index[category_name]
      else
        mark_as_invalid(entry, attribute: "category",
                               error: I18n.t(:error_not_found_in_database,
                                             name: category_name))
      end
    end

    def tax_and_shipping_validation(entry, type, category, index)
      return if category.blank?

      if index.key? category
        entry.public_send("#{type}_category_id=", index[category])
      else
        mark_as_invalid(entry, attribute: "#{type}_category",
                               error: I18n.t('admin.product_import.model.category_not_found'))
      end
    end

    def shipping_presence_validation(entry)
      return if entry.shipping_category_id

      mark_as_invalid(entry, attribute: "shipping_category",
                             error: I18n.t(:error_required))
    end

    def product_validation(entry)
      products = Spree::Product.where(supplier_id: entry.enterprise_id,
                                      name: entry.name,
                                      deleted_at: nil)

      if products.empty?
        mark_as_new_product(entry)
        return
      end

      products.each { |product| product_field_errors(entry, product) }

      products.flat_map(&:variants).each do |existing_variant|
        if entry_matches_existing_variant?(entry, existing_variant) &&
           existing_variant.deleted_at.nil?
          return mark_as_existing_variant(entry, existing_variant)
        end
      end

      mark_as_new_variant(entry, products.first.id)
    end

    def mark_as_new_product(entry)
      new_product = Spree::Product.new
      new_product.assign_attributes(
        entry.assignable_attributes.except('id', 'on_hand', 'on_demand', 'display_name')
      )
      new_product.supplier_id = entry.producer_id
      entry.on_hand = 0 if entry.on_hand.nil?

      if new_product.valid?
        entry.validates_as = 'new_product' unless entry.errors?
      else
        mark_as_invalid(entry, product_validations: new_product.errors)
      end
    end

    def mark_as_existing_variant(entry, existing_variant)
      existing_variant.assign_attributes(
        entry.assignable_attributes.except('id', 'product_id', 'variant_unit', 'variant_unit_name',
                                           'variant_unit_scale', 'primary_taxon_id')
      )
      check_on_hand_nil(entry, existing_variant)

      if existing_variant.valid?
        entry.product_object = existing_variant
        entry.validates_as = 'existing_variant' unless entry.errors?
        updates_count_per_enterprise(entry.enterprise_id) unless entry.errors?
      else
        mark_as_invalid(entry, product_validations: existing_variant.errors)
      end
    end

    def product_field_errors(entry, existing_product)
      EntryValidator.non_updatable_fields.each do |display_name, attribute|
        next if attributes_match?(attribute, existing_product, entry) ||
                attributes_blank?(attribute, existing_product, entry)
        next if ignore_when_updating_product?(attribute)

        mark_as_invalid(entry, attribute: display_name,
                               error: I18n.t('admin.product_import.model.not_updatable'))
      end
    end

    def attributes_match?(attribute, existing_product, entry)
      existing_product_value = existing_product.public_send(attribute)
      entry_value = entry.public_send(attribute)
      existing_product_value == convert_to_trusted_type(entry_value, existing_product_value)
    end

    def ignore_when_updating_product?(attribute)
      SKIP_VALIDATE_ON_UPDATE.include? attribute
    end

    def convert_to_trusted_type(untrusted_attribute, trusted_attribute)
      case trusted_attribute
      when Integer
        untrusted_attribute.to_i
      when Float
        untrusted_attribute.to_f
      else
        untrusted_attribute.to_s
      end
    end

    def attributes_blank?(attribute, existing_product, entry)
      existing_product.public_send(attribute).blank? && entry.public_send(attribute).blank?
    end

    def permission_by_name?(enterprise_name)
      @editable_enterprises.key?(enterprise_name)
    end

    def permission_by_id?(enterprise_id)
      @editable_enterprises.value?(Integer(enterprise_id))
    end

    def inventory_permission?(enterprise_id, producer_id)
      @current_user.admin? ||
        @inventory_permissions[enterprise_id]&.include?(producer_id)
    end

    def mark_as_invalid(entry, options = {})
      if options[:attribute] && options[:error]
        entry.errors.add(options[:attribute], options[:error])
      end

      entry.product_validations = options[:product_validations] if options[:product_validations]
    end

    def mark_as_not_updatable(entry, attribute)
      mark_as_invalid(entry, attribute: attribute,
                             error: I18n.t("admin.product_import.model.not_updatable"))
    end

    def mark_as_values_must_be_same(entry, attribute)
      mark_as_invalid(entry, attribute: attribute,
                             error: I18n.t("admin.product_import.model.values_must_be_same"))
    end

    def import_into_inventory?
      @import_settings.dig(:settings, 'import_into') == 'inventories'
    end

    def validate_inventory_item(entry, variant_override)
      if variant_override.valid? && !entry.errors?
        mark_as_inventory_item(entry, variant_override)
      else
        mark_as_invalid(entry, product_validations: variant_override.errors)
      end
    end

    def create_inventory_item(entry, existing_variant)
      find_or_initialize_variant_override(entry, existing_variant).tap do |variant_override|
        check_variant_override_stock_settings(entry, variant_override)

        variant_override.assign_attributes(import_date: @import_time)
        variant_override.assign_attributes(entry.attributes.slice('price', 'on_demand'))
      end
    end

    def mark_as_inventory_item(entry, variant_override)
      if variant_override.id
        entry.validates_as = 'existing_inventory_item'
        entry.product_object = variant_override
        updates_count_per_enterprise(entry.enterprise_id) unless entry.errors?
      else
        entry.validates_as = 'new_inventory_item'
        entry.product_object = variant_override
      end
    end

    def updates_count_per_enterprise(enterprise_id)
      if @reset_counts[enterprise_id] &&
         @reset_counts[enterprise_id][:updates_count]

        @reset_counts[enterprise_id][:updates_count] += 1
      else
        @reset_counts[enterprise_id] = { updates_count: 1 }
      end
    end

    def check_on_hand_nil(entry, object)
      return if entry.on_hand.present?

      object.on_hand = 0 if object.respond_to?(:on_hand)
      entry.on_hand_nil = true
    end

    def check_variant_override_stock_settings(entry, object)
      object.count_on_hand = entry.on_hand.presence
      object.on_demand = object.count_on_hand.blank? if entry.on_demand.blank?
      entry.on_hand_nil = object.count_on_hand.blank?
    end

    def all_entries_for_product(entry)
      all_entries_by_product[entries_by_product_key(entry)]
    end

    def all_entries_by_product
      @all_entries_by_product ||= @all_entries.group_by do |entry|
        entries_by_product_key(entry)
      end
    end

    def entries_by_product_key(entry)
      [entry.producer.to_s, entry.name.to_s]
    end
  end
end
