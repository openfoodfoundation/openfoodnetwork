require 'roo'

class Admin::ProductImportController < Spree::Admin::BaseController

  before_filter :validate_upload_presence, except: :index

  def import
    # Save uploaded file to tmp directory
    @filepath = save_uploaded_file(params[:file])
    @importer = ProductImporter.new(File.new(@filepath), editable_enterprises)

    check_file_errors @importer
    check_spreadsheet_has_data @importer

    @tax_categories = Spree::TaxCategory.order('is_default DESC, name ASC')
    @shipping_categories = Spree::ShippingCategory.order('name ASC')
  end

  def save
    @importer = ProductImporter.new(File.new(params[:filepath]), editable_enterprises, params[:settings])
    @importer.save_all if @importer.has_valid_entries?
  end

  private

  def validate_upload_presence
    unless params[:file] || (params[:filepath] && File.exist?(params[:filepath]))
      redirect_to '/admin/product_import', notice: 'File not found or could not be opened'
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
      redirect_to '/admin/product_import', notice: 'No data found in spreadsheet'
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
