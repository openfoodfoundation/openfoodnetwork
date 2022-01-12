# Google requires an API key with a billing account to use their API.
# The key is stored in .env[.*] files.

Geocoder.configure(
  timeout: ENV.fetch('GEOCODER_TIMEOUT', 6).to_i,
  lookup: ENV.fetch('GEOCODER_SERVICE', :google).to_sym,
  use_https: true,
  api_key: ENV.fetch('GEOCODER_API_KEY', ENV["GOOGLE_MAPS_API_KEY"])
)
