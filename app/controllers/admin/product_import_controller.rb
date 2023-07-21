# frozen_string_literal: true

require 'roo'

module Admin
  class ProductImportController < Spree::Admin::BaseController
    before_action :validate_upload_presence, except: %i[index guide validate_data]

    def index
      @product_categories = Spree::Taxon.order('name ASC').pluck(:name).uniq
      @tax_categories = Spree::TaxCategory.order('name ASC').pluck(:name)
      @shipping_categories = Spree::ShippingCategory.order('name ASC').pluck(:name)
    end

    def import
      @filepath = save_uploaded_file(params[:file])
      @importer = ProductImport::ProductImporter.new(File.new(@filepath), spree_current_user,
                                                     params[:settings])
      @original_filename = params[:file].try(:original_filename)
      @non_updatable_fields = ProductImport::EntryValidator.non_updatable_fields

      return if contains_errors? @importer

      @ams_data = ams_data
    end

    def validate_data
      return unless process_data('validate')

      render json: @importer.import_results, response: 200
    end

    def save_data
      return unless process_data('save')

      render json: @importer.save_results, response: 200
    end

    def reset_absent_products
      @importer = ProductImport::ProductImporter.new(
        File.new(file_path),
        spree_current_user,
        import_into: params[:import_into],
        enterprises_to_reset: params[:enterprises_to_reset],
        updated_ids: params[:updated_ids],
        settings: params[:settings]
      )

      if params.key?(:enterprises_to_reset) && params.key?(:updated_ids)
        @importer.reset_absent(params[:updated_ids])
      end

      render json: @importer.products_reset_count
    end

    private

    def validate_upload_presence
      unless params[:file] || (params[:filepath] && File.exist?(params[:filepath]))
        redirect_to '/admin/product_import', notice: I18n.t(:product_import_file_not_found_notice)
      end
    end

    def process_data(method)
      @importer = ProductImport::ProductImporter.new(
        File.new(file_path),
        spree_current_user,
        start: params[:start],
        end: params[:end],
        settings: params[:settings]
      )

      begin
        @importer.public_send("#{method}_entries")
      rescue StandardError => e
        render json: e.message, response: 500
        return false
      end

      true
    end

    def contains_errors?(importer)
      if importer.errors.present?
        redirect_to '/admin/product_import', notice: @importer.errors.full_messages.to_sentence
        return true
      end

      check_spreadsheet_has_data importer
    end

    def check_spreadsheet_has_data(importer)
      unless importer.item_count
        redirect_to '/admin/product_import',
                    notice: I18n.t(:product_import_no_data_in_spreadsheet_notice)
        true
      end
    end

    def save_uploaded_file(upload)
      extension = File.extname(upload.original_filename)
      directory = Dir.mktmpdir 'product_import'
      File.open(File.join(directory, "import#{extension}"), 'wb') do |f|
        data = UploadSanitizer.new(upload.read).call
        f.write(data)
        f.path
      end
    end

    def ams_data
      {
        filepath: @filepath,
        item_count: @importer.item_count,
        enterprise_product_counts: @importer.enterprise_products,
        import_url: main_app.admin_product_import_process_async_path,
        save_url: main_app.admin_product_import_save_async_path,
        reset_url: main_app.admin_product_import_reset_async_path,
        importSettings: @importer.import_settings,
      }
    end

    # Define custom model class for Cancan permissions
    def model_class
      ProductImport::ProductImporter
    end

    def file_path
      @file_path ||= validate_file_path(sanitize_file_path(params[:filepath]))
    end

    def sanitize_file_path(file_path)
      FilePathSanitizer.new.sanitize(file_path, on_error: method(:raise_invalid_file_path))
    end

    def validate_file_path(file_path)
      return file_path if file_path.to_s.match?(TEMP_FILE_PATH_REGEX)

      raise_invalid_file_path
    end

    def raise_invalid_file_path
      redirect_to '/admin/product_import',
                  notice: I18n.t(:product_import_no_data_in_spreadsheet_notice)
      raise 'Invalid File Path'
    end
    TEMP_FILE_PATH_REGEX = %r{^/tmp/product_import[A-Za-z0-9-]*/import\.csv$}
  end
end
