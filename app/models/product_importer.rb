require 'roo'

class ProductImporter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :total_supplier_products, :supplier_products, :updated_ids

  def initialize(file, current_user, import_settings={})
    if file.is_a?(File)
      @file = file
      @sheet = open_spreadsheet
      @entries = []
      @valid_entries = {}
      @invalid_entries = {}

      @products_to_create = {}
      @variants_to_create = {}
      @variants_to_update = {}

      @products_created = 0
      @variants_created = 0
      @variants_updated = 0
      @inventory_created = 0
      @inventory_updated = 0

      @import_time = Time.zone.now
      @import_settings = import_settings || {}

      @current_user = current_user
      @editable_enterprises = {}
      @inventory_permissions = {}

      @total_supplier_products = 0
      @supplier_products = {}
      @reset_counts = {}
      @updated_ids = []
      @products_reset_count = 0

      init_product_importer if @sheet
    else
      self.errors.add(:importer, I18n.t(:product_importer_file_error))
    end
  end

  def persisted?
    false # ActiveModel
  end

  def has_entries?
    @entries.count > 0
  end

  def has_valid_entries?
    @entries.each do |entry|
      return true if entry.validates_as.present?
    end
    false
  end

  def item_count
    @sheet ? @sheet.last_row - 1 : 0
  end

  def reset_counts
    # Return indexed data about existing product count, reset count, and updates count per supplier
    @reset_counts.each do |supplier_id, values|
      values[:updates_count] = 0 if values[:updates_count].blank?

      if values[:updates_count] and values[:existing_products]
        @reset_counts[supplier_id][:reset_count] = values[:existing_products] - values[:updates_count]
      end
    end
    @reset_counts
  end

  def suppliers_index
    index = @suppliers_index || build_suppliers_index
    index.sort_by{ |k,v| v.to_i }.reverse.to_h
  end

  def all_entries
    @entries
  end

  def entries_json
    entries = {}
    @entries.each do |entry|
      entries[entry.line_number] = {
        attributes: entry.displayable_attributes,
        validates_as: entry.validates_as,
        errors: entry.invalid_attributes
      }
    end
    entries.to_json
  end

  def table_headings
    @entries.first.displayable_attributes.keys.map(&:humanize) if @entries.first
  end

  def products_created_count
    @products_created + @variants_created
  end

  def products_updated_count
    @variants_updated
  end

  def inventory_created_count
    @inventory_created
  end

  def inventory_updated_count
    @inventory_updated
  end

  def products_reset_count
    @products_reset_count
  end

  def total_saved_count
    @products_created + @variants_created + @variants_updated + @inventory_created + @inventory_updated
  end

  def save_all
    save_all_valid
    delete_uploaded_file
  end

  def import_results
    {entries: entries_json, reset_counts: reset_counts}
  end

  def save_results
    {
      results: {
        products_created: products_created_count,
        products_updated: products_updated_count,
        inventory_created: inventory_created_count,
        inventory_updated: inventory_updated_count,
        products_reset: products_reset_count,
      },
      updated_ids: updated_ids,
      errors: errors.full_messages
    }
  end

  def permission_by_name?(supplier_name)
    @editable_enterprises.has_key?(supplier_name)
  end

  def permission_by_id?(supplier_id)
    @editable_enterprises.has_value?(Integer(supplier_id))
  end

  def inventory_permission?(supplier_id, producer_id)
    @current_user.admin? or ( @inventory_permissions[supplier_id] and @inventory_permissions[supplier_id].include? producer_id )
  end

  def validate_entries
    @entries.each do |entry|
      supplier_validation(entry)
      unit_fields_validation(entry)

      next if entry.supplier_id.blank?

      if import_into_inventory?(entry)
        producer_validation(entry)
        inventory_validation(entry)
      else
        category_validation(entry)
        tax_and_shipping_validation(entry)
        product_validation(entry)
      end
    end
  end

  def import_into_inventory?(entry)
    entry.supplier_id and @import_settings[:settings][entry.supplier_id.to_s]['import_into'] == 'inventories'
  end

  def save_entries
    validate_entries
    save_all_valid
  end

  def reset_absent(updated_ids)
    @products_created = updated_ids.count
    @updated_ids = updated_ids
    reset_absent_items
  end

  private

  def init_product_importer
    init_permissions
    if @import_settings and @import_settings.has_key?(:start) and @import_settings.has_key?(:end)
      build_entries_in_range
    else
      build_entries
    end
    build_categories_index
    build_suppliers_index
    build_tax_and_shipping_indexes
    build_producers_index
    count_existing_items unless @import_settings.has_key?(:start)
  end

  def init_permissions
    permissions = OpenFoodNetwork::Permissions.new(@current_user)

    permissions.editable_enterprises.
      order('is_primary_producer ASC, name').
      map { |e| @editable_enterprises[e.name] = e.id }

    @inventory_permissions = permissions.variant_override_enterprises_per_hub
  end

  def open_spreadsheet
    if accepted_mimetype
      Roo::Spreadsheet.open(@file, extension: accepted_mimetype)
    else
      self.errors.add(:importer, I18n.t(:product_importer_spreadsheet_error))
      delete_uploaded_file
      nil
    end
  end

  def accepted_mimetype
    File.extname(@file.path).in?('.csv', '.xls', '.xlsx', '.ods') ? @file.path.split('.').last.to_sym : false
  end

  def headers
    @sheet.row(1)
  end

  def rows
    return [] unless @sheet and @sheet.last_row
    (2..@sheet.last_row).map do |i|
      @sheet.row(i)
    end
  end

  def build_entries_in_range
    start_line = @import_settings[:start]
    end_line = @import_settings[:end]

    (start_line..end_line).each do |i|
      line_number = i + 1
      row = @sheet.row(line_number)
      row_data = Hash[[headers, row].transpose]
      entry = SpreadsheetEntry.new(row_data)
      entry.line_number = line_number
      @entries.push entry
      return if @sheet.last_row == line_number # TODO: test
    end
  end

  def build_entries
    rows.each_with_index do |row, i|
      row_data = Hash[[headers, row].transpose]
      entry = SpreadsheetEntry.new(row_data)
      entry.line_number = i + 2
      @entries.push entry
    end
    @entries
  end

  def validate_all
    @entries.each do |entry|
      supplier_validation(entry)
      unit_fields_validation(entry)

      next if entry.supplier_id.blank?

      if import_into_inventory?(entry)
        producer_validation(entry)
        inventory_validation(entry)
      else
        category_validation(entry)
        tax_and_shipping_validation(entry)
        product_validation(entry)
      end
    end

    count_existing_items
    delete_uploaded_file if item_count.zero? or !has_valid_entries?
  end

  # def importing_into_inventory?
  #   @import_settings[:import_into] == 'inventories'
  # end

  def inventory_validation(entry)
    # Find product with matching supplier and name
    match = Spree::Product.where(supplier_id: entry.producer_id, name: entry.name, deleted_at: nil).first

    if match.nil?
      mark_as_invalid(entry, attribute: 'name', error: I18n.t('admin.product_import.model.no_product'))
      return
    end

    match.variants.each do |existing_variant|
      unit_scale = match.variant_unit_scale
      unscaled_units = entry.unscaled_units || 0
      entry.unit_value = unscaled_units * unit_scale

      if existing_variant.display_name == entry.display_name and existing_variant.unit_value == entry.unit_value.to_f
        variant_override = create_inventory_item(entry, existing_variant)
        validate_inventory_item(entry, variant_override)
        return
      end
    end

    mark_as_invalid(entry, attribute: 'product', error: I18n.t('admin.product_import.model.not_found'))
  end

  def create_inventory_item(entry, existing_variant)
    existing_variant_override = VariantOverride.where(variant_id: existing_variant.id, hub_id: entry.supplier_id).first

    variant_override = existing_variant_override || VariantOverride.new(variant_id: existing_variant.id, hub_id: entry.supplier_id)
    variant_override.assign_attributes(count_on_hand: entry.on_hand, import_date: @import_time)
    check_on_hand_nil(entry, variant_override)
    variant_override.assign_attributes(entry.attributes.slice('price', 'on_demand'))

    variant_override
  end

  def validate_inventory_item(entry, variant_override)
    if variant_override.valid? and !entry.has_errors?
      mark_as_inventory_item(entry, variant_override)
    else
      mark_as_invalid(entry, product_validations: variant_override.errors)
    end
  end

  def mark_as_inventory_item(entry, variant_override)
    if variant_override.id
      entry.is_a_valid('existing_inventory_item')
      entry.product_object = variant_override
      updates_count_per_supplier(entry.supplier_id) unless entry.has_errors?
    else
      entry.is_a_valid('new_inventory_item')
      entry.product_object = variant_override
    end
  end

  def count_existing_items
    @suppliers_index.each do |supplier_name, supplier_id|
      next unless supplier_id and permission_by_id?(supplier_id)

      products_count =
        if import_into_inventory_by_supplier?(supplier_id)
          VariantOverride.
            where('variant_overrides.hub_id IN (?)', supplier_id).
            count
        else
          Spree::Variant.
            joins(:product).
            where('spree_products.supplier_id IN (?)
            AND spree_variants.is_master = false
            AND spree_variants.deleted_at IS NULL', supplier_id).
            count
        end

      @supplier_products[supplier_id] = products_count
      @total_supplier_products += products_count
    end
  end

  def import_into_inventory_by_supplier?(supplier_id)
    @import_settings[:settings] and @import_settings[:settings][supplier_id.to_s] and @import_settings[:settings][supplier_id.to_s]['import_into'] == 'inventories'
  end

  def supplier_validation(entry)
    supplier_name = entry.supplier

    if supplier_name.blank?
      mark_as_invalid(entry, attribute: "supplier", error: I18n.t(:error_required))
      return
    end

    unless supplier_exists?(supplier_name)
      mark_as_invalid(entry, attribute: "supplier", error: I18n.t(:error_not_found_in_database, name: supplier_name))
      return
    end

    unless permission_by_name?(supplier_name)
      mark_as_invalid(entry, attribute: "supplier", error: I18n.t(:error_no_permission_for_enterprise, name: supplier_name))
      return
    end

    entry.supplier_id = @suppliers_index[supplier_name]
  end

  def producer_validation(entry)
    producer_name = entry.producer

    if producer_name.blank?
      mark_as_invalid(entry, attribute: "producer", error: I18n.t('admin.product_import.model.blank'))
      return
    end

    unless producer_exists?(producer_name)
      mark_as_invalid(entry, attribute: "producer", error: "\"#{producer_name}\" #{I18n.t('admin.product_import.model.not_found')}")
      return
    end

    unless inventory_permission?(entry.supplier_id, @producers_index[producer_name])
      mark_as_invalid(entry, attribute: "producer", error: "\"#{producer_name}\": #{I18n.t('admin.product_import.model.inventory_no_permission')}")
      return
    end

    entry.producer_id = @producers_index[producer_name]
  end

  def supplier_exists?(supplier_name)
    @suppliers_index[supplier_name]
  end

  def producer_exists?(producer_name)
    @producers_index[producer_name]
  end

  def category_validation(entry)
    category_name = entry.category

    if category_name.blank?
      mark_as_invalid(entry, attribute: "category", error: I18n.t(:error_required))
      return
    end

    if category_exists?(category_name)
      entry.primary_taxon_id = @categories_index[category_name]
    else
      mark_as_invalid(entry, attribute: "category", error: I18n.t(:error_not_found_in_database, name: category_name))
    end
  end

  def tax_and_shipping_validation(entry)
    tax_validation(entry)
    shipping_validation(entry)
  end

  def tax_validation(entry)
    return if entry.tax_category.blank?
    if @tax_index.has_key? entry.tax_category
      entry.tax_category_id = @tax_index[entry.tax_category]
    else
      mark_as_invalid(entry, attribute: "tax_category", error: I18n.t('admin.product_import.model.not_found'))
    end
  end

  def shipping_validation(entry)
    return if entry.shipping_category.blank?
    if @shipping_index.has_key? entry.shipping_category
      entry.shipping_category_id = @shipping_index[entry.shipping_category]
    else
      mark_as_invalid(entry, attribute: "shipping_category", error: I18n.t('admin.product_import.model.not_found'))
    end
  end

  def category_exists?(category_name)
    @categories_index[category_name]
  end

  def mark_as_invalid(entry, options={})
    entry.errors.add(options[:attribute], options[:error]) if options[:attribute] and options[:error]
    entry.product_validations = options[:product_validations] if options[:product_validations]
  end

  # Minimise db queries by getting a list of suppliers to look
  # up, instead of doing a query for each entry in the spreadsheet
  def build_suppliers_index
    @suppliers_index = {}
    @entries.each do |entry|
      supplier_name = entry.supplier
      supplier_id = @suppliers_index[supplier_name] ||
          Enterprise.find_by_name(supplier_name, select: 'id, name').try(:id)
      @suppliers_index[supplier_name] = supplier_id
    end
    @suppliers_index
  end

  def build_producers_index
    @producers_index = {}
    @entries.each do |entry|
      next unless entry.producer
      producer_name = entry.producer
      producer_id = @producers_index[producer_name] ||
          Enterprise.find_by_name(producer_name, select: 'id, name').try(:id)
      @producers_index[producer_name] = producer_id
    end
    @producers_index
  end

  def build_categories_index
    @categories_index = {}
    @entries.each do |entry|
      category_name = entry.category
      category_id = @categories_index[category_name] || Spree::Taxon.find_by_name(category_name, :select => 'id, name').try(:id)
      @categories_index[category_name] = category_id
    end
    @categories_index
  end

  def build_tax_and_shipping_indexes
    @tax_index = {}
    @shipping_index = {}
    Spree::TaxCategory.select(%i[id name]).map { |tc| @tax_index[tc.name] = tc.id }
    Spree::ShippingCategory.select(%i[id name]).map { |sc| @shipping_index[sc.name] = sc.id }
  end

  def save_all_valid
    @entries.each do |entry|
      if import_into_inventory?(entry)
        save_new_inventory_item entry if entry.is_a_valid? 'new_inventory_item'
        save_existing_inventory_item entry if entry.is_a_valid? 'existing_inventory_item'
      else
        save_new_product entry if entry.is_a_valid? 'new_product'
        save_new_variant entry if entry.is_a_valid? 'new_variant'
        save_existing_variant entry if entry.is_a_valid? 'existing_variant'
      end
    end

    self.errors.add(:importer, I18n.t(:product_importer_products_save_error)) if total_saved_count.zero?

    reset_absent_items unless @import_settings.has_key?(:start)
    total_saved_count
  end

  def save_new_product(entry)
    @already_created ||= {}
    # If we've already added a new product with these attributes
    # from this spreadsheet, mark this entry as a new variant with
    # the new product id, as this is a now variant of that product...
    if @already_created[entry.supplier_id] and @already_created[entry.supplier_id][entry.name]
      product_id = @already_created[entry.supplier_id][entry.name]
      mark_as_new_variant(entry, product_id)
      return
    end

    product = Spree::Product.new()
    product.assign_attributes(entry.attributes.except('id'))
    assign_defaults(product, entry)

    if product.save
      ensure_variant_updated(product, entry)
      @products_created += 1
      @updated_ids.push product.variants.first.id
    else
      self.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", product.errors.full_messages)
    end

    @already_created[entry.supplier_id] = {entry.name => product.id}
  end

  def display_in_inventory(variant_override, is_new=false)
    unless is_new
      existing_item = InventoryItem.where(
        variant_id: variant_override.variant_id,
        enterprise_id: variant_override.hub_id
      ).first

      if existing_item
        existing_item.assign_attributes(visible: true)
        existing_item.save
        return
      end
    end

    InventoryItem.new(
      variant_id: variant_override.variant_id,
      enterprise_id: variant_override.hub_id,
      visible: true
    ).save
  end

  def save_new_inventory_item(entry)
    new_item = entry.product_object
    assign_defaults(new_item, entry)
    new_item.import_date = @import_time

    if new_item.valid? and new_item.save
      display_in_inventory(new_item, true)
      @inventory_created += 1
      @updated_ids.push new_item.id
    else
      self.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", new_item.errors.full_messages)
    end
  end

  def save_existing_inventory_item(entry)
    existing_item = entry.product_object
    assign_defaults(existing_item, entry)
    existing_item.import_date = @import_time

    if existing_item.valid? and existing_item.save
      display_in_inventory(existing_item)
      @inventory_updated += 1
      @updated_ids.push existing_item.id
    else
      self.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", existing_item.errors.full_messages)
    end
  end

  def save_new_variant(entry)
    new_variant = entry.product_object
    assign_defaults(new_variant, entry)
    new_variant.import_date = @import_time

    if new_variant.valid? and new_variant.save
      @variants_created += 1
      @updated_ids.push new_variant.id
    else
      self.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", new_variant.errors.full_messages)
    end
  end

  def save_existing_variant(entry)
    variant = entry.product_object
    assign_defaults(variant, entry)
    variant.import_date = @import_time

    if variant.valid? and variant.save
      @variants_updated += 1
      @updated_ids.push variant.id
    else
      self.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", variant.errors.full_messages)
    end
  end

  def reset_absent_items
    return if total_saved_count.zero? or @updated_ids.empty? or !@import_settings.has_key?(:settings)
    suppliers_to_reset_products = []
    suppliers_to_reset_inventories = []

    @import_settings[:settings].each do |enterprise_id, settings|
      suppliers_to_reset_products.push enterprise_id if settings['reset_all_absent'] and permission_by_id?(enterprise_id) and !import_into_inventory_by_supplier?(enterprise_id)
      suppliers_to_reset_inventories.push enterprise_id if settings['reset_all_absent'] and permission_by_id?(enterprise_id) and import_into_inventory_by_supplier?(enterprise_id)
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # items that were not present in the uploaded spreadsheet
    unless suppliers_to_reset_inventories.empty?
      @products_reset_count += VariantOverride.
        where('variant_overrides.hub_id IN (?)
        AND variant_overrides.id NOT IN (?)', suppliers_to_reset_inventories, @updated_ids).
        update_all(count_on_hand: 0)
    end

    unless suppliers_to_reset_products.empty?
      @products_reset_count += Spree::Variant.joins(:product).
        where('spree_products.supplier_id IN (?)
        AND spree_variants.id NOT IN (?)
        AND spree_variants.is_master = false
        AND spree_variants.deleted_at IS NULL', suppliers_to_reset_products, @updated_ids).
        update_all(count_on_hand: 0)
    end
  end

  def assign_defaults(object, entry)
    return unless @import_settings.has_key?(:settings) and @import_settings[:settings][entry.supplier_id.to_s] and @import_settings[:settings][entry.supplier_id.to_s]['defaults']

    @import_settings[:settings][entry.supplier_id.to_s]['defaults'].each do |attribute, setting|
      next unless setting['active']

      case setting['mode']
      when 'overwrite_all'
        object.assign_attributes(attribute => setting['value'])
      when 'overwrite_empty'
        if object.send(attribute).blank? or ((attribute == 'on_hand' or attribute == 'count_on_hand') and entry.on_hand_nil)
          object.assign_attributes(attribute => setting['value'])
        end
      end
    end
  end

  def ensure_variant_updated(product, entry)
    # Ensure attributes are copied to new product's variant
    variant = product.variants.first
    variant.display_name = entry.display_name if entry.display_name
    variant.on_demand = entry.on_demand if entry.on_demand
    variant.import_date = @import_time
    variant.save
  end

  def unit_fields_validation(entry)
    unit_types = ['g', 'kg', 't', 'ml', 'l', 'kl', '']

    # unit must be present and not nil
    unless entry.units and entry.units.present?
      #self.errors.add('units', "can't be blank")
      mark_as_invalid(entry, attribute: 'units', error: I18n.t('admin.product_import.model.blank'))
    end

    return if import_into_inventory?(entry)

    # unit_type must be valid type
    if entry.unit_type and entry.unit_type.present?
      unit_type = entry.unit_type.to_s.strip.downcase
      #self.errors.add('unit_type', "incorrect value") unless unit_types.include?(unit_type)
      mark_as_invalid(entry, attribute: 'unit_type', error: I18n.t('admin.product_import.model.incorrect_value')) unless unit_types.include?(unit_type)
    end

    # variant_unit_name must be present if unit_type not present
    if !entry.unit_type or (entry.unit_type and entry.unit_type.blank?)
      #self.errors.add('variant_unit_name', "can't be blank if unit_type is blank") unless attrs.has_key? 'variant_unit_name' and attrs['variant_unit_name'].present?
      mark_as_invalid(entry, attribute: 'variant_unit_name', error: I18n.t('admin.product_import.model.conditional_blank')) unless entry.variant_unit_name and entry.variant_unit_name.present?
    end
  end

  def product_validation(entry)
    # Find product with matching supplier and name
    match = Spree::Product.where(supplier_id: entry.supplier_id, name: entry.name, deleted_at: nil).first

    # If no matching product was found, create a new product
    if match.nil?
      mark_as_new_product(entry)
      return
    end

    # Otherwise, if a variant exists with matching display_name and unit_value, update it
    match.variants.each do |existing_variant|
      if existing_variant.display_name == entry.display_name \
        && existing_variant.unit_value == entry.unit_value.to_f \
        && existing_variant.deleted_at.nil?

        mark_as_existing_variant(entry, existing_variant)
        return
      end
    end

    # Otherwise, a variant with sufficiently matching attributes doesn't exist; create a new one
    mark_as_new_variant(entry, match.id)
  end

  def mark_as_new_product(entry)
    new_product = Spree::Product.new()
    new_product.assign_attributes(entry.attributes.except('id'))

    if new_product.valid?
      entry.is_a_valid 'new_product' unless entry.has_errors?
    else
      mark_as_invalid(entry, product_validations: new_product.errors)
    end
  end

  def mark_as_existing_variant(entry, existing_variant)
    existing_variant.assign_attributes(entry.attributes.except('id', 'product_id'))
    check_on_hand_nil(entry, existing_variant)

    if existing_variant.valid?
      entry.product_object = existing_variant
      entry.is_a_valid 'existing_variant' unless entry.has_errors?
      updates_count_per_supplier(entry.supplier_id) unless entry.has_errors?
    else
      mark_as_invalid(entry, product_validations: existing_variant.errors)
    end
  end

  def mark_as_new_variant(entry, product_id)
    new_variant = Spree::Variant.new(entry.attributes.except('id', 'product_id'))
    new_variant.product_id = product_id
    check_on_hand_nil(entry, new_variant)

    if new_variant.valid?
      entry.product_object = new_variant
      entry.is_a_valid 'new_variant' unless entry.has_errors?
    else
      mark_as_invalid(entry, product_validations: new_variant.errors)
    end
  end

  def updates_count_per_supplier(supplier_id)
    if @reset_counts[supplier_id] \
    and @reset_counts[supplier_id][:updates_count]
      @reset_counts[supplier_id][:updates_count] += 1
    else
      @reset_counts[supplier_id] = {updates_count: 1}
    end
  end

  def check_on_hand_nil(entry, object)
    return if entry.on_hand.present?

    object.on_hand = 0 if object.respond_to?(:on_hand)
    object.count_on_hand = 0 if object.respond_to?(:count_on_hand)
    entry.on_hand_nil = true
  end

  def delete_uploaded_file
    # Only delete if file is in '/tmp/product_import' directory
    return unless @file.path == Rails.root.join('tmp', 'product_import').to_s

    File.delete(@file)
  end
end
