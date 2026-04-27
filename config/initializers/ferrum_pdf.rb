# frozen_string_literal: true

FerrumPdf.configure do |config|
  config.process_timeout = 60
  config.window_size = [1280, 800]

  config.pdf_options.format = Rails.env.test? ? :A3 : :A4
  config.pdf_options.print_background = true

  next unless ENV["CI"] || ENV["DOCKER"]

  config.browser_options = {
    "no-sandbox" => nil,
    "disable-dev-shm-usage" => nil,
  }
end
