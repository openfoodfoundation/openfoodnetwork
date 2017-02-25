require 'roo'

class ProductImporter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :valid_entries, :invalid_entries

  def initialize(file, editable_enterprises, options={})
    if file.is_a?(File)
      @file = file
      @options = options
      @sheet = open_spreadsheet
      @valid_entries = {}
      @invalid_entries = {}

      @products_to_create = []
      @variants_to_create = []
      @variants_to_update = []
      
      @products_created = 0
      @variants_created = 0
      @variants_updated = 0

      @editable_enterprises = {}
      editable_enterprises.map { |e| @editable_enterprises[e.name] = e.id }

      validate_all
    else
      self.errors.add(:importer, "error: no file uploaded")
    end
  end

  def persisted?
    false #ActiveModel, not ActiveRecord
  end

  # Private methods below which only work with a valid spreadsheet object can
  # be called publicly via here if the spreadsheet was successfully loaded,
  # otherwise they return nil (without error).
  def method_missing(method, *args, &block)
    if self.respond_to?(method, include_private=true)
      @sheet ? self.send(method, *args, &block) : nil
    else
      super
    end
  end

  private

  def open_spreadsheet
    if accepted_mimetype
      @sheet = Roo::Spreadsheet.open(@file, extension: accepted_mimetype)
    else
      self.errors.add(:importer, "could not proccess file: invalid filetype")
      nil
    end
  end

  def accepted_mimetype
    File.extname(@file.path).in?(['.csv', '.xls', '.xlsx', '.ods']) ? @file.path.split('.').last.to_sym : false
  end

  def headers
    @sheet.row(1)
  end

  def rows
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
      line_number = i+2

      supplier_validation(entry, line_number)
      category_validation(entry, line_number)

      # Ensure on_hand isn't nil because Spree::Product and
      # Spree::Variant each validate this differently
      entry['on_hand'] = 0 if entry['on_hand'].nil?

      set_update_status(entry, line_number)
      mark_as_valid(entry, line_number) unless entry_invalid?(line_number)
    end
  end

  def entry_invalid?(line_number)
    !!@invalid_entries[line_number]
  end

  def supplier_validation(entry, line_number)
    # Fetch/assign and validate supplier id
    suppliers_index = @suppliers_index || get_suppliers_index
    supplier_name = entry['supplier']
    if supplier_name.blank?
      mark_as_invalid(entry, line_number, "Supplier name field is empty")
    else
      if suppliers_index[supplier_name]
        entry['supplier_id'] = suppliers_index[supplier_name]
      else
        mark_as_invalid(entry, line_number, "Supplier \"#{supplier_name}\" not found in database")
      end

      # Check enterprise permissions
      unless @editable_enterprises[supplier_name]
        mark_as_invalid(entry, line_number, "You do not have permission to manage products for \"#{supplier_name}\"")
      end
    end
  end

  def category_validation(entry, line_number)
    # Fetch/assign and validate category id
    categories_index = @categories_index || get_categories_index
    category_name = entry['category']
    if category_name.blank?
      mark_as_invalid(entry, line_number, "Category field is empty")
    else
      if categories_index[category_name]
        entry['primary_taxon_id'] = categories_index[category_name]
      else
        mark_as_invalid(entry, line_number, "Category \"#{category_name}\" not found in database")
      end
    end
  end

  def mark_as_valid(entry, line_number)
    @valid_entries[line_number] = {entry: entry}
  end

  def mark_as_invalid(entry, line_number, errors)
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
    updated = {}
    @products_to_create.each do |entry|
      # If we've already added a new product with these attributes from
      # this spreadsheet, pass this entry to @variants_to_create with
      # the new product id, as this is a now variant of that product...
      if updated[entry['supplier_id']] && updated[entry['supplier_id']][entry['name']]
        product_id = updated[entry['supplier_id']][entry['name']]
        new_variant = Spree::Variant.new(entry.except('id', 'product_id'))
        new_variant.product_id = product_id
        @variants_to_create.push(new_variant)
        next
      end

      product = Spree::Product.new()
      product.assign_attributes(entry.except('id'))
      if product.save
        # Ensure display_name and on_demand are copied to new variant
        if entry['display_name'] || entry['on_demand']
          variant = product.variants.first
          variant.display_name = entry['display_name'] if entry['display_name']
          variant.on_demand = entry['on_demand'] if entry['on_demand']
          variant.save
        end
        @products_created += 1
      else
        self.errors.add(:importer, product.errors.full_messages)
      end

      updated[entry['supplier_id']] = {entry['name'] => product.id}
    end

    @variants_to_update.each do |variant|
      if variant.save
        @variants_updated += 1
      else
        self.errors.add(:importer, variant.errors.full_messages)
      end
    end

    @variants_to_create.each do |new_variant|
      if new_variant.save
        @variants_created += 1
      else
        self.errors.add(:importer, new_variant.errors.full_messages)
      end
    end

    self.errors.add(:importer, "did not save any products successfully") if updated_count == 0

    updated_count
  end

  def set_update_status(entry, line_number)
    # Find product with matching supplier and name
    match = Spree::Product.where(supplier_id: entry['supplier_id'], name: entry['name'], deleted_at: nil).first

    # If no matching product was found, create a new product
    if match.nil?
      mark_as_new_product(entry, line_number)
      return
    end

    # Otherwise, if a variant exists with matching display_name and unit_value, update it
    match.variants.each do |existing_variant|
      if existing_variant.display_name == entry['display_name'] && existing_variant.unit_value == Float(entry['unit_value'])
        mark_as_existing_variant(entry, line_number, existing_variant)
        return
      end
    end

    # Otherwise, a variant with sufficiently matching attributes doesn't exist; create a new one
    mark_as_new_variant(entry, line_number)
  end

  def mark_as_new_product(entry, line_number)
    new_product = Spree::Product.new()
    new_product.assign_attributes(entry.except('id'))
    if new_product.valid?
      @products_to_create.push(entry) unless entry_invalid?(line_number)
    else
      mark_as_invalid(entry, line_number, new_product.errors.full_messages)
    end
  end

  def mark_as_existing_variant(entry, line_number, existing_variant)
    existing_variant.assign_attributes(entry.except('id', 'product_id'))
    if existing_variant.valid?
      @variants_to_update.push(existing_variant) unless entry_invalid?(line_number)
    else
      mark_as_invalid(entry, line_number, existing_variant.errors.full_messages)
    end
  end

  def mark_as_new_variant(entry, line_number)
    new_variant = Spree::Variant.new(entry.except('id', 'product_id'))
    new_variant.product_id = match.id
    if new_variant.valid?
      @variants_to_create.push(new_variant) unless entry_invalid?(line_number)
    else
      mark_as_invalid(entry, line_number, new_variant.errors.full_messages)
    end
  end

  def has_valid_entries?
    valid_count > 0
  end

  def item_count
    @sheet.last_row - 1
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

  def products_created
    @products_created + @variants_created
  end

  def products_updated
    @variants_updated
  end

  def updated_count
    @products_created + @variants_created + @variants_updated
  end
end
