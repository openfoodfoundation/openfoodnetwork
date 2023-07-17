# frozen_string_literal: true

require 'roo'

module Admin
  class ProductImportController < Spree::Admin::BaseController
    include ProductImportFiles
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
  end
end
