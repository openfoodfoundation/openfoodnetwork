# frozen_string_literal: true

# This is the main class for product import. It handles the initial processing of the CSV file,
# and begins the processing of the spreadsheet entries by the other product import classes.
# As spreadsheets can contain any number of entries (1000+), the import is split into smaller chunks
# of 100 items, and processed sequentially over a number of requests to avoid server timeouts.
# The various bits of collated info such as file upload status, per-item errors or user feedback
# on the saving process are made available to the controller through this object.

require 'roo'

module ProductImport
  class ProductImporter
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_reader :entries, :updated_ids, :import_settings

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

    def product_field_errors?
      @entries.each do |entry|
        return true if entry.errors.messages.
          value?([I18n.t('admin.product_import.model.not_updatable')])
      end
      false
    end

    def reset_counts
      # Return indexed data about existing product count, reset count, and
      # updates count per enterprise
      @reset_counts.each do |enterprise_id, values|
        values[:updates_count] = 0 if values[:updates_count].blank?

        if values[:updates_count] && values[:existing_products]
          @reset_counts[enterprise_id][:reset_count] =
            values[:existing_products] - values[:updates_count]
        end
      end
      @reset_counts
    end

    def enterprises_index
      @spreadsheet_data.enterprises_index
    end

    def enterprise_products
      @processor&.enterprise_products
    end

    def total_enterprise_products
      @processor.total_enterprise_products
    end

    def entries_json
      entries = {}
      @entries.each do |entry|
        entries[entry.line_number] = {
          attributes: entry.displayable_attributes,
          validates_as: entry.validates_as,
          errors: entry.invalid_attributes,
          product_validations: entry.product_validations
        }
      end
      entries.to_json
    end

    def table_headings
      return unless @entries.first

      @entries.first.displayable_attributes.keys.map do |key|
        I18n.t "admin.product_import.product_headings.#{key}"
      end
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

    def permission_by_id?(enterprise_id)
      @editable_enterprises.value?(Integer(enterprise_id))
    end

    private

    def init_product_importer
      init_permissions

      if staged_import?
        build_entries_in_range
      else
        build_entries
      end

      @spreadsheet_data = SpreadsheetData.new(@entries, @import_settings)
      @validator = EntryValidator.new(@current_user, @import_time, @spreadsheet_data,
                                      @editable_enterprises, @inventory_permissions, @reset_counts,
                                      @import_settings, build_all_entries)
      @processor = EntryProcessor.new(self, @validator, @import_settings, @spreadsheet_data,
                                      @editable_enterprises, @import_time, @updated_ids)

      @processor.count_existing_items unless staged_import?
    end

    def staged_import?
      @import_settings&.key?(:start) && @import_settings&.key?(:end)
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
        Roo::Spreadsheet.open(@file, extension: accepted_mimetype, encoding: Encoding::UTF_8)
      else
        errors.add(:importer, I18n.t(:product_importer_spreadsheet_error))
        delete_uploaded_file
        nil
      end
    end

    def accepted_mimetype
      return false unless ['.csv'].include? File.extname(@file.path)

      @file.path.split('.').last.to_sym
    end

    def headers
      @sheet.row(1)
    end

    def rows
      return [] unless @sheet&.last_row

      @sheet.parse(clean: true)

      (2..@sheet.last_row).map do |i|
        @sheet.row(i)
      end
    rescue ArgumentError => e
      if e.message.include? 'invalid byte sequence'
        errors.add(:importer, I18n.t('admin.product_import.model.encoding_error'))
      else
        errors.add(:importer, I18n.t('admin.product_import.model.unexpected_error',
                                     error_message: e.message))
      end
      []
    rescue CSV::MalformedCSVError => e
      add_malformed_csv_error e.message
      []
    end

    # This error is raised twice because init_product_importer calls both
    # build_entries and buils_all_entries
    def add_malformed_csv_error(error_message)
      unless errors.added?(:importer, I18n.t('admin.product_import.model.malformed_csv',
                                             error_message: error_message))
        errors.add(:importer, I18n.t('admin.product_import.model.malformed_csv',
                                     error_message: error_message))
      end
    end

    def build_entries_in_range
      # In the JS, start and end are calculated like this:
      # start = (batchIndex * $scope.batchSize) + 1
      # end = (batchIndex + 1) * $scope.batchSize
      start_data_index = @import_settings[:start] - 1
      end_data_index = @import_settings[:end] - 1

      data_rows = rows[start_data_index..end_data_index]
      @entries = build_entries_from_rows(data_rows, start_data_index)
    end

    def build_entries
      @entries = build_entries_from_rows(rows)
    end

    def build_all_entries
      build_entries_from_rows(rows)
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

    def build_entries_from_rows(rows, offset = 0)
      rows.each_with_index.inject([]) do |entries, (row, i)|
        row_data = Hash[[headers, row].transpose]
        entry = SpreadsheetEntry.new(row_data)
        entry.line_number = offset + i + 2
        entries.push entry
      end
    end
  end
end
