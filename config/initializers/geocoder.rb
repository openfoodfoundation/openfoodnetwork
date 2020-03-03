# Google requires an API key with a billing account to use their API.
# The key is stored in config/application.yml.
Geocoder.configure(
  lookup: :google,
  use_https: true,
  api_key: ENV.fetch('GOOGLE_MAPS_API_KEY', nil)
)
