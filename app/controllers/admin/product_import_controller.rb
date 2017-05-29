require 'roo'

class Admin::ProductImportController < Spree::Admin::BaseController

  before_filter :validate_upload_presence, except: [:index, :process_data]

  def import
    # Save uploaded file to tmp directory
    @filepath = save_uploaded_file(params[:file])
    @importer = ProductImporter.new(File.new(@filepath), spree_current_user, params[:settings])
    @original_filename = params[:file].try(:original_filename)

    check_file_errors @importer
    check_spreadsheet_has_data @importer

    @tax_categories = Spree::TaxCategory.order('is_default DESC, name ASC')
    @shipping_categories = Spree::ShippingCategory.order('name ASC')
  end

  # def save
  #   @importer = ProductImporter.new(File.new(params[:filepath]), spree_current_user, params[:settings])
  #   @importer.save_all if @importer.has_valid_entries?
  #   @import_into = params[:settings][:import_into]
  # end

  def process_data
    @importer = ProductImporter.new(File.new(params[:filepath]), spree_current_user, {start: params[:start], end: params[:end], settings: params[:settings]})

    begin
      @importer.validate_entries
    rescue Exception => e
      render json: e.message, response: 500
    end

    render json: @importer.import_results, response: 200
  end

  def save_data
    @importer = ProductImporter.new(File.new(params[:filepath]), spree_current_user, {start: params[:start], end: params[:end], settings: params[:settings]})

    begin
      @importer.save_entries
    rescue Exception => e
      render json: e.message, response: 500
    end

    render json: @importer.save_results, response: 200
  end

  def reset_absent_products
    @importer = ProductImporter.new(File.new(params[:filepath]), spree_current_user, {import_into: params[:import_into], enterprises_to_reset: params[:enterprises_to_reset], updated_ids: params[:updated_ids], 'settings' => params[:settings]})

    if params.has_key?(:enterprises_to_reset) and params.has_key?(:updated_ids)
      @importer.reset_absent(params[:updated_ids])
    end

    render json: @importer.products_reset_count
  end

  private

  def validate_upload_presence
    unless params[:file] || (params[:filepath] && File.exist?(params[:filepath]))
      redirect_to '/admin/product_import', notice: I18n.t(:product_import_file_not_found_notice)
      return
    end
  end

  def check_file_errors(importer)
    if importer.errors.present?
      redirect_to '/admin/product_import', notice: @importer.errors.full_messages.to_sentence
      return
    end
  end

  def check_spreadsheet_has_data(importer)
    unless importer.item_count
      redirect_to '/admin/product_import', notice: I18n.t(:product_import_no_data_in_spreadsheet_notice)
      return
    end
  end

  def save_uploaded_file(upload)
    filename = 'import' + Time.now.strftime('%d-%m-%Y-%H-%M-%S')
    extension = '.' + upload.original_filename.split('.').last
    directory = 'tmp/product_import'
    Dir.mkdir(directory) unless File.exists?(directory)
    File.open(Rails.root.join(directory, filename+extension), 'wb') do |f|
      f.write(upload.read)
      f.path
    end
  end

  # Define custom model class for Cancan permissions
  def model_class
    ProductImporter
  end
end
