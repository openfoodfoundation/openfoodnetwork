# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'

require 'spree/core'

Rails.application.reloader.to_prepare do
  Spree.config do |config|
    config.site_url = ENV['SITE_URL'] if ENV['SITE_URL']
    config.site_name = ENV['SITE_NAME'] if ENV['SITE_NAME']
    config.shipping_instructions = true
    config.address_requires_state = true
    config.admin_interface_logo = '/default_images/ofn-logo.png'

    # S3 settings
    config.s3_bucket = ENV['S3_BUCKET'] if ENV['S3_BUCKET']
    config.s3_access_key = ENV['S3_ACCESS_KEY'] if ENV['S3_ACCESS_KEY']
    config.s3_secret = ENV['S3_SECRET'] if ENV['S3_SECRET']
    config.use_s3 = true if ENV['S3_BUCKET']
    config.s3_headers = ENV['S3_HEADERS'] if ENV['S3_HEADERS']
    config.s3_protocol = ENV.fetch('S3_PROTOCOL', 'https')
  end

  # Read mail configuration from ENV vars at boot time and ensure the values are
  # applied correctly in Spree::Config.
  MailConfiguration.apply!

  # TODO Work out why this is necessary
  # Seems like classes within OFN module become 'uninitialized' when server reloads
  # unless the empty module is explicity 'registered' here. Something to do with autoloading?
  module OpenFoodNetwork
  end
end
