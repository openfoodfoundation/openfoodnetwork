require 'roo'

class Admin::ProductImportController < Spree::Admin::BaseController

  before_filter :check_upload, except: :index

  def import
    # Save uploaded file to tmp directory
    @filepath = save_upload(params[:file])
    @importer = ProductImporter.new(File.new(@filepath), editable_enterprises)

    if @importer.errors.present?
      flash[:notice] = @importer.errors.full_messages.to_sentence
    end
  end

  def save
    file = File.new(params[:filepath])
    @importer = ProductImporter.new(file, editable_enterprises)
    @importer.save_all_valid

    if @importer.updated_count && @importer.updated_count > 0
      File.delete(file)
      flash[:success] = "#{@importer.updated_count} records updated successfully"
    else
      flash[:notice] = @importer.errors.full_messages.to_sentence
    end
  end

  private

  def check_upload
    unless params[:file] || (params[:filepath] && File.exist?(params[:filepath]))
      redirect_to '/admin/product_import', :notice => 'File not found or could not be opened'
      return
    end
  end

  def save_upload(upload)
    filename = Time.now.strftime('%d-%m-%Y-%H-%M-%S')
    extension = '.' + upload.original_filename.split('.').last
    File.open(Rails.root.join('tmp', filename+extension), 'wb') do |f|
      f.write(upload.read)
      f.path
    end
  end

  # Define custom model class for Cancan permissions
  def model_class
    ProductImporter
  end
end