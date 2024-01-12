# frozen_string_literal: true

module FileHelper
  def black_logo_file
    Rack::Test::UploadedFile.new(black_logo_path, "image/png")
  end

  def white_logo_file
    Rack::Test::UploadedFile.new(white_logo_path, "image/png")
  end

  def black_logo_path
    Rails.root.join('app/webpacker/images/logo-black.png')
  end

  def white_logo_path
    Rails.root.join('app/webpacker/images/logo-white.png')
  end

  def terms_pdf_file
    file_path = Rails.public_path.join("Terms-of-service.pdf")
    fixture_file_upload(file_path, "application/pdf")
  end
end
