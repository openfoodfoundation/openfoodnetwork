require 'roo'

class ProductImporter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :total_supplier_products

  def initialize(file, editable_enterprises, import_settings={})
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

      @import_settings = import_settings
      @editable_enterprises = {}
      editable_enterprises.map { |e| @editable_enterprises[e.name] = e.id }

      @total_supplier_products = 0
      @products_to_reset = {}
      @updated_ids = []

      init_product_importer if @sheet
    else
      self.errors.add(:importer, 'error: no file uploaded')
    end
  end

  def persisted?
    false #ActiveModel, not ActiveRecord
  end

  def has_valid_entries?
    valid_count and valid_count > 0
  end

  def item_count
    @sheet ? @sheet.last_row - 1 : 0
  end

  def products_to_reset
    # Return indexed data about existing product count, reset count, and updates count per supplier
    @products_to_reset.each do |supplier_id, values|
      values[:updates_count] = 0 if values[:updates_count].blank?

      if values[:updates_count] and values[:existing_products]
        @products_to_reset[supplier_id][:reset_count] = values[:existing_products] - values[:updates_count]
      end
    end
    @products_to_reset
  end

  def valid_count
    @valid_entries.count
  end

  def invalid_count
    @invalid_entries.count
  end

  def products_create_count
    @products_to_create.count + @variants_to_create.count
  end

  def products_update_count
    @variants_to_update.count
  end

  def suppliers_index
    index = @suppliers_index || build_suppliers_index
    index.sort_by{ |k,v| v.to_i }.reverse.to_h
  end

  def all_entries
    invalid_entries.merge(products_to_create).merge(products_to_update).sort.to_h
  end

  def invalid_entries
    @invalid_entries
  end

  def products_to_create
    @products_to_create.merge(@variants_to_create)
  end

  def products_to_update
    @variants_to_update
  end

  def products_created_count
    @products_created + @variants_created
  end

  def products_updated_count
    @variants_updated
  end

  def products_reset_count
    @products_reset_count || 0
  end

  def total_saved_count
    @products_created + @variants_created + @variants_updated
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

  private

  def init_product_importer
    build_entries
    build_categories_index
    build_suppliers_index
    validate_all
  end

  def open_spreadsheet
    if accepted_mimetype
      Roo::Spreadsheet.open(@file, extension: accepted_mimetype)
    else
      self.errors.add(:importer, 'could not process file: invalid filetype')
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

  def build_entries
    rows.each_with_index do |row, i|
      row_data = Hash[[headers, row].transpose]
      entry = SpreadsheetEntry.new(row_data)
      entry.line_number = i+2
      @entries.push entry
    end
    @entries
  end

  def validate_all
    @entries.each do |entry|
      supplier_validation(entry)
      category_validation(entry)
      set_update_status(entry)

      mark_as_valid(entry) unless entry_invalid?(entry.line_number)
    end

    count_existing_products
    delete_uploaded_file if item_count.zero? or valid_count.zero?
  end

  def count_existing_products
    @suppliers_index.each do |supplier_name, supplier_id|
      if supplier_id and permission_by_id?(supplier_id)
        products_count = Spree::Variant.joins(:product).
          where('spree_products.supplier_id IN (?)
          AND spree_variants.is_master = false
          AND spree_variants.deleted_at IS NULL', supplier_id).
          count

        if @products_to_reset[supplier_id]
          @products_to_reset[supplier_id][:existing_products] = products_count
        else
          @products_to_reset[supplier_id] = {existing_products: products_count}
        end

        @total_supplier_products += products_count
      end
    end
  end

  def entry_invalid?(line_number)
    !!@invalid_entries[line_number]
  end

  def supplier_validation(entry)
    supplier_name = entry.supplier

    if supplier_name.blank?
      mark_as_invalid(entry, attribute: "supplier", error: "can't be blank")
      return
    end

    unless supplier_exists?(supplier_name)
      mark_as_invalid(entry, attribute: "supplier", error: "\"#{supplier_name}\" not found in database")
      return
    end

    unless permission_by_name?(supplier_name)
      mark_as_invalid(entry, attribute: "supplier", error: "\"#{supplier_name}\": you do not have permission to manage products for this enterprise")
      return
    end

    entry.supplier_id = @suppliers_index[supplier_name]
  end

  def supplier_exists?(supplier_name)
    @suppliers_index[supplier_name]
  end

  def category_validation(entry)
    category_name = entry.category

    if category_name.blank?
      mark_as_invalid(entry, attribute: "category", error: "can't be blank")
      return
    end

    if category_exists?(category_name)
      entry.primary_taxon_id = @categories_index[category_name]
    else
      mark_as_invalid(entry, attribute: "category", error: "\"#{category_name}\" not found in database")
    end
  end

  def category_exists?(category_name)
    @categories_index[category_name]
  end

  def mark_as_valid(entry)
    @valid_entries[entry.line_number] = entry
  end

  def mark_as_invalid(entry, options={})
    entry.errors.add(options[:attribute], options[:error]) if options[:attribute] and options[:error]
    entry.product_validations = options[:product_validations] if options[:product_validations]

    @invalid_entries[entry.line_number] = entry
  end

  # Minimise db queries by getting a list of suppliers to look
  # up, instead of doing a query for each entry in the spreadsheet
  def build_suppliers_index
    @suppliers_index = {}
    @entries.each do |entry|
      supplier_name = entry.supplier
      supplier_id = @suppliers_index[supplier_name] ||
          Enterprise.find_by_name(supplier_name, :select => 'id, name').try(:id)
      @suppliers_index[supplier_name] = supplier_id
    end
    @suppliers_index
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
    already_created = {}
    @products_to_create.each do |line_number, entry|
      # If we've already added a new product with these attributes
      # from this spreadsheet, mark this entry as a new variant with
      # the new product id, as this is a now variant of that product...
      if already_created[entry.supplier_id] and already_created[entry.supplier_id][entry.name]
        product_id = already_created[entry.supplier_id][entry.name]
        mark_as_new_variant(entry, product_id)
        next
      end

      product = Spree::Product.new()
      product.assign_attributes(entry.attributes.except('id'))
      assign_defaults(product, entry.attributes)
      if product.save
        ensure_variant_updated(product, entry)
        @products_created += 1
        @updated_ids.push product.variants.first.id
      else
        self.errors.add("Line #{line_number}:", product.errors.full_messages) #TODO: change
      end

      already_created[entry.supplier_id] = {entry.name => product.id}
    end

    @variants_to_update.each do |line_number, entry|
      variant = entry.product_object
      assign_defaults(variant, entry.attributes)
      if variant.valid? and variant.save
        @variants_updated += 1
        @updated_ids.push variant.id
      else
        self.errors.add("Line #{line_number}:", variant.errors.full_messages) #TODO: change
      end
    end

    @variants_to_create.each do |line_number, entry|
      new_variant = entry.product_object
      assign_defaults(new_variant, entry.attributes)
      if new_variant.valid? and new_variant.save
        @variants_created += 1
        @updated_ids.push new_variant.id
      else
        self.errors.add("Line #{line_number}:", new_variant.errors.full_messages)
      end
    end

    self.errors.add(:importer, "did not save any products successfully") if total_saved_count.zero?

    reset_absent_products
    total_saved_count
  end

  def reset_absent_products
    return if total_saved_count.zero?

    enterprises_to_reset = []
    @import_settings.each do |enterprise_id, settings|
      enterprises_to_reset.push enterprise_id if settings['reset_all_absent'] and permission_by_id?(enterprise_id)
    end

    unless enterprises_to_reset.empty? or @updated_ids.empty?
      # For selected enterprises; set stock to zero for all products
      # that were not present in the uploaded spreadsheet
      @products_reset_count = Spree::Variant.joins(:product).
        where('spree_products.supplier_id IN (?)
        AND spree_variants.id NOT IN (?)
        AND spree_variants.is_master = false
        AND spree_variants.deleted_at IS NULL', enterprises_to_reset, @updated_ids).
        update_all(count_on_hand: 0)
    end
  end

  def assign_defaults(object, entry)
    @import_settings[entry['supplier_id'].to_s]['defaults'].each do |attribute, setting|
      case setting['mode']
        when 'overwrite_all'
          object.assign_attributes(attribute => setting['value'])
        when 'overwrite_empty'
          if object.send(attribute).blank? or (attribute == 'on_hand' and entry['on_hand_nil'])
            object.assign_attributes(attribute => setting['value'])
          end
      end
    end
  end

  def ensure_variant_updated(product, entry)
    # Ensure display_name and on_demand are copied to new product's variant
    if entry.display_name || entry.on_demand
      variant = product.variants.first
      variant.display_name = entry.display_name if entry.display_name
      variant.on_demand = entry.on_demand if entry.on_demand
      variant.save
    end
  end

  def set_update_status(entry)
    # Find product with matching supplier and name
    match = Spree::Product.where(supplier_id: entry.supplier_id, name: entry.name, deleted_at: nil).first

    # If no matching product was found, create a new product
    if match.nil?
      mark_as_new_product(entry)
      return
    end

    # Otherwise, if a variant exists with matching display_name and unit_value, update it
    match.variants.each do |existing_variant|
      if existing_variant.display_name == entry.display_name && existing_variant.unit_value == Float(entry.unit_value)
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
      @products_to_create[entry.line_number] = entry unless entry_invalid?(entry.line_number)
    else
      mark_as_invalid(entry, product_validations: new_product.errors)
    end
  end

  def mark_as_existing_variant(entry, existing_variant)
    existing_variant.assign_attributes(entry.attributes.except('id', 'product_id'))
    check_on_hand_nil(entry, existing_variant)
    if existing_variant.valid?
      entry.product_object = existing_variant
      @variants_to_update[entry.line_number] = entry unless entry_invalid?(entry.line_number)
      updates_count_per_supplier(entry.supplier_id) unless entry_invalid?(entry.line_number)
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
      @variants_to_create[entry.line_number] = entry unless entry_invalid?(entry.line_number)
    else
      mark_as_invalid(entry, product_validations: new_variant.errors)
    end
  end

  def updates_count_per_supplier(supplier_id)
    if @products_to_reset[supplier_id] and @products_to_reset[supplier_id][:updates_count]
      @products_to_reset[supplier_id][:updates_count] += 1
    else
      @products_to_reset[supplier_id] = {updates_count: 1}
    end
  end

  def check_on_hand_nil(entry, variant)
    if entry.on_hand.blank?
      variant.on_hand = 0
      entry.on_hand_nil = true
    end
  end

  def delete_uploaded_file
    # Only delete if file is in '/tmp/product_import' directory
    if @file.path == Rails.root.join('tmp', 'product_import').to_s
      File.delete(@file)
    end
  end
end
