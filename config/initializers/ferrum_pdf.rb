# frozen_string_literal: true

FerrumPdf.configure do |config|
  config.process_timeout = 60
  config.window_size = [1280, 800]

  # Conversion from PDF to text struggles with multi-line text.
  # We avoid that by printing on bigger pages in test environment.
  # https://github.com/openfoodfoundation/openfoodnetwork/pull/9674
  config.pdf_options.format = Rails.env.test? ? :A3 : :A4
  config.pdf_options.scale = 0.85 # Scale down the content to fit better on the page, matching the wicked_pdf scale
  config.pdf_options.print_background = true

  next unless ENV["CI"] || ENV["DOCKER"]

  config.browser_options = {
    "no-sandbox" => nil,
    "disable-dev-shm-usage" => nil,
  }
end
