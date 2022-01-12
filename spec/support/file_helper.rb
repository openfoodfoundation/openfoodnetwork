# frozen_string_literal: true

module FileHelper
  def black_logo_file
    File.open(black_logo_path)
  end

  def white_logo_file
    File.open(black_logo_path)
  end

  def black_logo_path
    Rails.root.join('app/webpacker/images/logo-black.png')
  end

  def white_logo_path
    Rails.root.join('app/webpacker/images/logo-white.png')
  end
end
