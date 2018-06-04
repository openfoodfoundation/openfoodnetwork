require 'roo'

module Admin
  class ProductImportController < Spree::Admin::BaseController
    before_filter :validate_upload_presence, except: %i[index guide validate_data]

    def guide
      @product_categories = Spree::Taxon.order('name ASC').pluck(:name).uniq
      @tax_categories = Spree::TaxCategory.order('name ASC').pluck(:name)
      @shipping_categories = Spree::ShippingCategory.order('name ASC').pluck(:name)
    end

    def import
      # Save uploaded file to tmp directory
      @filepath = save_uploaded_file(params[:file])
      @importer = ProductImport::ProductImporter.new(File.new(@filepath), spree_current_user, params[:settings])
      @original_filename = params[:file].try(:original_filename)

      check_file_errors @importer
      check_spreadsheet_has_data @importer

      @tax_categories = Spree::TaxCategory.order('is_default DESC, name ASC')
      @shipping_categories = Spree::ShippingCategory.order('name ASC')
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
      @importer = ProductImport::ProductImporter.new(File.new(params[:filepath]), spree_current_user, import_into: params[:import_into], enterprises_to_reset: params[:enterprises_to_reset], updated_ids: params[:updated_ids], settings: params[:settings])

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
      @importer = ProductImport::ProductImporter.new(File.new(params[:filepath]), spree_current_user, start: params[:start], end: params[:end], settings: params[:settings])

      begin
        @importer.send("#{method}_entries")
      rescue StandardError => e
        render json: e.message, response: 500
        return false
      end

      true
    end

    def check_file_errors(importer)
      if importer.errors.present?
        redirect_to '/admin/product_import', notice: @importer.errors.full_messages.to_sentence
      end
    end

    def check_spreadsheet_has_data(importer)
      unless importer.item_count
        redirect_to '/admin/product_import', notice: I18n.t(:product_import_no_data_in_spreadsheet_notice)
      end
    end

    def save_uploaded_file(upload)
      filename = 'import' + Time.zone.now.strftime('%d-%m-%Y-%H-%M-%S')
      extension = '.' + upload.original_filename.split('.').last
      directory = 'tmp/product_import'
      Dir.mkdir(directory) unless File.exist?(directory)
      File.open(Rails.root.join(directory, filename + extension), 'wb') do |f|
        f.write(upload.read)
        f.path
      end
    end

    # Define custom model class for Cancan permissions
    def model_class
      ProductImport::ProductImporter
    end
  end
end
