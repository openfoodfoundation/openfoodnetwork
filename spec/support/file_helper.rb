# frozen_string_literal: true

module FileHelper
  def black_logo_file
    Rack::Test::UploadedFile.new(black_logo_path)
  end

  def white_logo_file
    Rack::Test::UploadedFile.new(white_logo_path)
  end

  def black_logo_path
    Rails.root.join('app/webpacker/images/logo-black.png')
  end

  def white_logo_path
    Rails.root.join('app/webpacker/images/logo-white.png')
  end
end
