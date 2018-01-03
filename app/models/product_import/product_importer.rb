require 'roo'

module ProductImport
  class ProductImporter
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_reader :updated_ids

    def initialize(file, current_user, import_settings = {})
      unless file.is_a?(File)
        errors.add(:importer, I18n.t(:product_importer_file_error))
        return
      end

      @file = file
      @sheet = open_spreadsheet
      @entries = []

      @import_time = Time.zone.now
      @import_settings = import_settings || {}

      @current_user = current_user
      @editable_enterprises = {}
      @inventory_permissions = {}

      @reset_counts = {}
      @updated_ids = []

      init_product_importer if @sheet
    end

    def persisted?
      false # ActiveModel
    end

    def entries?
      @entries.count > 0
    end

    def valid_entries?
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

        if values[:updates_count] && values[:existing_products]
          @reset_counts[supplier_id][:reset_count] = values[:existing_products] - values[:updates_count]
        end
      end
      @reset_counts
    end

    def suppliers_index
      index = @spreadsheet_data.suppliers_index
      index.sort_by{ |_k, v| v.to_i }.reverse.to_h
    end

    def supplier_products
      @processor.supplier_products
    end

    def total_supplier_products
      @processor.total_supplier_products
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
      @processor.products_created + @processor.variants_created
    end

    def products_updated_count
      @processor.variants_updated
    end

    def inventory_created_count
      @processor.inventory_created
    end

    def inventory_updated_count
      @processor.inventory_updated
    end

    def products_reset_count
      @processor.products_reset_count
    end

    def total_saved_count
      @processor.total_saved_count
    end

    def import_results
      { entries: entries_json, reset_counts: reset_counts }
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

    def validate_entries
      @validator.validate_all(@entries)
    end

    def save_entries
      validate_entries
      save_all_valid
    end

    def reset_absent(updated_ids)
      @products_created = updated_ids.count
      @updated_ids = updated_ids
      @processor.reset_absent_items
    end

    def permission_by_id?(supplier_id)
      @editable_enterprises.value?(Integer(supplier_id))
    end

    private

    def init_product_importer
      init_permissions

      if staged_import?
        build_entries_in_range
      else
        build_entries
      end

      @spreadsheet_data = SpreadsheetData.new(@entries)
      @validator = EntryValidator.new(@current_user, @import_time, @spreadsheet_data, @editable_enterprises, @inventory_permissions, @reset_counts, @import_settings)
      @processor = EntryProcessor.new(self, @validator, @import_settings, @spreadsheet_data, @editable_enterprises, @import_time, @updated_ids)

      @processor.count_existing_items unless staged_import?
    end

    def staged_import?
      @import_settings && @import_settings.key?(:start) && @import_settings.key?(:end)
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
        errors.add(:importer, I18n.t(:product_importer_spreadsheet_error))
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
      return [] unless @sheet && @sheet.last_row
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
        break if @sheet.last_row == line_number
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

    def save_all_valid
      @processor.save_all(@entries)
      @processor.reset_absent_items unless staged_import?
      @processor.total_saved_count
    end

    def delete_uploaded_file
      return unless @file.path == Rails.root.join('tmp', 'product_import').to_s
      File.delete(@file)
    end
  end
end
