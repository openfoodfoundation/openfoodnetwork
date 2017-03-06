require 'roo'

class ProductImporter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  def initialize(file, editable_enterprises, import_settings={})
    if file.is_a?(File)
      @file = file
      @sheet = open_spreadsheet
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

      @non_display_attributes = 'id', 'product_id', 'variant_id', 'supplier_id', 'primary_taxon_id', 'category_id', 'shipping_category_id', 'tax_category_id', 'on_hand_nil'
      @supplier_products = {total: 0, by_supplier: {}}
      @updated_ids = []

      validate_all if @sheet
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

  def supplier_products
    # Return indexed data about existing product count and update count per supplier
    @supplier_products[:by_supplier].each do |supplier_id, supplier_data|
      supplier_data[:updates_count] = 0 if supplier_data[:updates_count].blank?

      if supplier_data[:updates_count] and supplier_data[:existing_products]
        @supplier_products[:by_supplier][supplier_id][:non_updated] = supplier_data[:existing_products] - supplier_data[:updates_count]
      end
    end
    @supplier_products
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
    @suppliers_index || get_suppliers_index
  end

  def invalid_entries
    entries = {}
    @invalid_entries.each do |line_number, data|
      entries[line_number] = {entry: data[:entry].except(*@non_display_attributes), errors: data[:errors]}
    end
    entries
  end

  def products_to_create
    entries = {}
    @products_to_create.merge(@variants_to_create).each do |line_number, data|
      entries[line_number] = {entry: data[:entry].except(*@non_display_attributes)}
    end
    entries
  end

  def products_to_update
    entries = {}
    @variants_to_update.each do |line_number, data|
      entries[line_number] = {entry: data[:entry].except(*@non_display_attributes)}
    end
    entries
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

  private

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

  def entries
    rows.map do |row|
      Hash[[headers, row].transpose]
    end
  end

  def validate_all
    entries.each_with_index do |entry, i|
      line_number = i+2 # Roo counts "line 2" as the first line of data

      supplier_validation(line_number, entry)
      category_validation(line_number, entry)
      set_update_status(line_number, entry)

      mark_as_valid(line_number, entry) unless entry_invalid?(line_number)
    end

    count_existing_products

    delete_uploaded_file if item_count.zero? or valid_count.zero?
  end

  def count_existing_products
    @suppliers_index.each do |supplier_name, supplier_id|
      if supplier_id
        products_count = Spree::Variant.joins(:product).
          where('spree_products.supplier_id IN (?)
          AND spree_variants.is_master = false
          AND spree_variants.deleted_at IS NULL', supplier_id).
          count

        if @supplier_products[:by_supplier][supplier_id]
          @supplier_products[:by_supplier][supplier_id][:existing_products] = products_count
        else
          @supplier_products[:by_supplier][supplier_id] = {existing_products: products_count}
        end

        @supplier_products[:total] += products_count
      end
    end
  end

  def entry_invalid?(line_number)
    !!@invalid_entries[line_number]
  end

  def supplier_validation(line_number, entry)
    suppliers_index = @suppliers_index || get_suppliers_index
    supplier_name = entry['supplier']

    if supplier_name.blank?
      mark_as_invalid(line_number, entry, "Supplier name field is empty")
      return
    end

    unless supplier_exists?(supplier_name)
      mark_as_invalid(line_number, entry, "Supplier \"#{supplier_name}\" not found in database")
      return
    end

    unless permission_to_manage?(supplier_name)
      mark_as_invalid(line_number, entry, "You do not have permission to manage products for \"#{supplier_name}\"")
      return
    end

    entry['supplier_id'] = suppliers_index[supplier_name]
  end

  def supplier_exists?(supplier_name)
    @suppliers_index[supplier_name]
  end

  def permission_to_manage?(supplier_name)
    @editable_enterprises.has_key?(supplier_name)
  end

  def category_validation(line_number, entry)
    categories_index = @categories_index || get_categories_index
    category_name = entry['category']

    if category_name.blank?
      mark_as_invalid(line_number, entry, "Category field is empty")
      entry['primary_taxon_id'] = Spree::Taxon.first.id # Removes a duplicate validation message
      return
    end

    if category_exists?(category_name)
      entry['primary_taxon_id'] = categories_index[category_name]
    else
      mark_as_invalid(line_number, entry, "Category \"#{category_name}\" not found in database")
    end
  end

  def category_exists?(category_name)
    @categories_index[category_name]
  end

  def mark_as_valid(line_number, entry)
    @valid_entries[line_number] = {entry: entry}
  end

  def mark_as_invalid(line_number, entry, errors)
    errors = [errors] if errors.is_a? String

    if entry_invalid?(line_number)
      @invalid_entries[line_number][:errors] += errors
    else
      @invalid_entries[line_number] = {entry: entry, errors: errors}
    end
  end

  # Minimise db queries by getting a list of suppliers to look
  # up, instead of doing a query for each entry in the spreadsheet
  def get_suppliers_index
    @suppliers_index ||= {}
    entries.each do |entry|
      supplier_name = entry['supplier']
      supplier_id = @suppliers_index[supplier_name] ||
          Enterprise.find_by_name(supplier_name, :select => 'id, name').try(:id)
      @suppliers_index[supplier_name] = supplier_id
    end
    @suppliers_index
  end

  def get_categories_index
    @categories_index ||= {}
    entries.each do |entry|
      category_name = entry['category']
      category_id = @categories_index[category_name] ||
          Spree::Taxon.find_by_name(category_name, :select => 'id, name').try(:id)
      @categories_index[category_name] = category_id
    end
    @categories_index
  end

  def save_all_valid
    already_created = {}
    @products_to_create.each do |line_number, data|
      entry = data[:entry]
      # If we've already added a new product with these attributes
      # from this spreadsheet, mark this entry as a new variant with
      # the new product id, as this is a now variant of that product...
      if already_created[entry['supplier_id']] and already_created[entry['supplier_id']][entry['name']]
        product_id = already_created[entry['supplier_id']][entry['name']]
        mark_as_new_variant(line_number, entry, product_id)
        next
      end

      product = Spree::Product.new()
      product.assign_attributes(entry.except('id'))
      assign_defaults(product, entry)
      if product.save
        ensure_variant_updated(entry, product)
        @products_created += 1
        @updated_ids.push product.variants.first.id
      else
        self.errors.add("Line #{line_number}:", product.errors.full_messages)
      end

      already_created[entry['supplier_id']] = {entry['name'] => product.id}
    end

    @variants_to_update.each do |line_number, data|
      variant = data[:variant]
      assign_defaults(variant, data[:entry])
      if variant.valid? and variant.save
        @variants_updated += 1
        @updated_ids.push variant.id
      else
        self.errors.add("Line #{line_number}:", variant.errors.full_messages)
      end
    end

    @variants_to_create.each do |line_number, data|
      new_variant = data[:variant]
      assign_defaults(new_variant, data[:entry])
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
      enterprises_to_reset.push enterprise_id if settings['reset_all_absent']
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

  def ensure_variant_updated(entry, product)
    # Ensure display_name and on_demand are copied to new product's variant
    if entry['display_name'] || entry['on_demand']
      variant = product.variants.first
      variant.display_name = entry['display_name'] if entry['display_name']
      variant.on_demand = entry['on_demand'] if entry['on_demand']
      variant.save
    end
  end

  def set_update_status(line_number, entry)
    # Find product with matching supplier and name
    match = Spree::Product.where(supplier_id: entry['supplier_id'], name: entry['name'], deleted_at: nil).first

    # If no matching product was found, create a new product
    if match.nil?
      mark_as_new_product(line_number, entry)
      return
    end

    # Otherwise, if a variant exists with matching display_name and unit_value, update it
    match.variants.each do |existing_variant|
      if existing_variant.display_name == entry['display_name'] && existing_variant.unit_value == Float(entry['unit_value'])
        mark_as_existing_variant(line_number, entry, existing_variant)
        return
      end
    end

    # Otherwise, a variant with sufficiently matching attributes doesn't exist; create a new one
    mark_as_new_variant(line_number, entry, match.id)
  end

  def mark_as_new_product(line_number, entry)
    new_product = Spree::Product.new()
    new_product.assign_attributes(entry.except('id'))
    if new_product.valid?
      @products_to_create[line_number] = {entry: entry} unless entry_invalid?(line_number)
    else
      mark_as_invalid(line_number, entry, new_product.errors.full_messages)
    end
  end

  def mark_as_existing_variant(line_number, entry, existing_variant)
    existing_variant.assign_attributes(entry.except('id', 'product_id'))
    check_on_hand_nil(entry, existing_variant)
    if existing_variant.valid?
      @variants_to_update[line_number] = {entry: entry, variant: existing_variant} unless entry_invalid?(line_number)
      updates_count_per_supplier(entry['supplier_id']) unless entry_invalid?(line_number)
    else
      mark_as_invalid(line_number, entry, existing_variant.errors.full_messages)
    end
  end

  def mark_as_new_variant(line_number, entry, product_id)
    new_variant = Spree::Variant.new(entry.except('id', 'product_id'))
    new_variant.product_id = product_id
    check_on_hand_nil(entry, new_variant)
    if new_variant.valid?
      @variants_to_create[line_number] = {entry: entry, variant: new_variant} unless entry_invalid?(line_number)
    else
      mark_as_invalid(line_number, entry, new_variant.errors.full_messages)
    end
  end

  def updates_count_per_supplier(supplier_id)
    if @supplier_products[:by_supplier][supplier_id] and @supplier_products[:by_supplier][supplier_id][:updates_count]
      @supplier_products[:by_supplier][supplier_id][:updates_count] += 1
    else
      @supplier_products[:by_supplier][supplier_id] = {updates_count: 1}
    end
  end

  def check_on_hand_nil(entry, variant)
    if entry['on_hand'].blank?
      variant.on_hand = 0
      entry['on_hand_nil'] = true
    end
  end

  def delete_uploaded_file
    # Only delete if file is in '/tmp/product_import' directory
    if @file.path == Rails.root.join('tmp', 'product_import').to_s
      File.delete(@file)
    end
  end
end
