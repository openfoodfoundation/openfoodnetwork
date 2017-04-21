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

      @import_time = DateTime.now
      @import_settings = import_settings

      @current_user = current_user
      @editable_enterprises = {}
      @inventory_permissions = {}

      @total_supplier_products = 0
      @supplier_products = {}
      @reset_counts = {}
      @updated_ids = []

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
      return true unless entry.validates_as.blank?
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
        errors: entry.invalid_attributes }
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
    @products_reset_count || 0
  end

  def total_saved_count
    @products_created + @variants_created + @variants_updated + @inventory_created + @inventory_updated
  end

  def save_all
    save_all_valid
    delete_uploaded_file
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

      if importing_into_inventory?
        producer_validation(entry)
        inventory_validation(entry)
      else
        category_validation(entry)
        product_validation(entry)
      end
    end
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
    if @import_settings.has_key?(:start) and @import_settings.has_key?(:end)
      build_entries_in_range
    else
      build_entries
    end
    build_categories_index
    build_suppliers_index
    build_producers_index if importing_into_inventory?
    #validate_all
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

      if importing_into_inventory?
        producer_validation(entry)
        inventory_validation(entry)
      else
        category_validation(entry)
        product_validation(entry)
      end
    end

    count_existing_items
    delete_uploaded_file if item_count.zero? or !has_valid_entries?
  end

  def importing_into_inventory?
    @import_settings[:import_into] == 'inventories'
  end

  def inventory_validation(entry)
    # Find product with matching supplier and name
    match = Spree::Product.where(supplier_id: entry.producer_id, name: entry.name, deleted_at: nil).first

    if match.nil?
      mark_as_invalid(entry, attribute: 'name', error: I18n.t('admin.product_import.model.no_product'))
      return
    end

    match.variants.each do |existing_variant|
      if existing_variant.display_name == entry.display_name and existing_variant.unit_value == Float(entry.unit_value)
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

      if importing_into_inventory?
        products_count = VariantOverride.
          where('variant_overrides.hub_id IN (?)', supplier_id).
          count
      else
        products_count = Spree::Variant.
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
      category_id = @categories_index[category_name] ||
          Spree::Taxon.find_by_name(category_name, :select => 'id, name').try(:id)
      @categories_index[category_name] = category_id
    end
    @categories_index
  end

  def save_all_valid
    @entries.each do |entry|
      if importing_into_inventory?
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
        enterprise_id: variant_override.hub_id).
        first

      if existing_item
        existing_item.assign_attributes(visible: true)
        existing_item.save
        return
      end
    end

    InventoryItem.new(
      variant_id: variant_override.variant_id,
      enterprise_id: variant_override.hub_id,
      visible: true).
      save
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
    return if total_saved_count.zero? or @updated_ids.empty? or !@import_settings.has_key?('settings')

    enterprises_to_reset = []
    @import_settings['settings'].each do |enterprise_id, settings|
      enterprises_to_reset.push enterprise_id if settings['reset_all_absent'] and permission_by_id?(enterprise_id)
    end

    return if enterprises_to_reset.empty?

    # For selected enterprises; set stock to zero for all products/inventory
    # items that were not present in the uploaded spreadsheet
    if importing_into_inventory?
      @products_reset_count = VariantOverride.
        where('variant_overrides.hub_id IN (?)
        AND variant_overrides.id NOT IN (?)', enterprises_to_reset, @updated_ids).
        update_all(count_on_hand: 0)
    else
      @products_reset_count = Spree::Variant.joins(:product).
        where('spree_products.supplier_id IN (?)
        AND spree_variants.id NOT IN (?)
        AND spree_variants.is_master = false
        AND spree_variants.deleted_at IS NULL', enterprises_to_reset, @updated_ids).
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
      and existing_variant.unit_value == Float(entry.unit_value) \
      and existing_variant.deleted_at == nil

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
    return unless entry.on_hand.blank?

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
