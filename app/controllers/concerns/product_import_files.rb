# frozen_string_literal: true

module ProductImportFiles
  extend ActiveSupport::Concern

  private

  def validate_upload_presence
    return if params[:file] || (params[:filepath] && File.exist?(params[:filepath]))

    redirect_to '/admin/product_import', notice: I18n.t(:product_import_file_not_found_notice)
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
    return if importer.item_count

    redirect_to '/admin/product_import',
                notice: I18n.t(:product_import_no_data_in_spreadsheet_notice)
    true
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
