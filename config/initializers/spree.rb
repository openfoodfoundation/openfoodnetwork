# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'

require "spree/core/environment"
require 'spree/product_filters'

# Due to a bug in ActiveRecord we need to load the tagging code in Gateway which
# should have inherited it from its parent PaymentMethod.
# We have to call it before loading the PaymentMethod decorator because the
# tagging code won't load twice within the inheritance chain.
# https://github.com/openfoodfoundation/openfoodnetwork/issues/3121
Spree::Gateway.class_eval do
  acts_as_taggable
end

# Spree stores attachent definitions in JSON. This converts the style name and format to
# strings. However, when paperclip encounters these, it doesn't recognise the format.
# Here we solve that problem by converting format and style name to symbols.
#
# eg. {'mini' => ['48x48>', 'png']} is converted to {mini: ['48x48>', :png]}
def format_styles(styles)
  styles_a = styles.map do |name, style|
    style[1] = style[1].to_sym if style.is_a? Array
    [name.to_sym, style]
  end

  Hash[styles_a]
end

def reformat_styles
  Spree::Image.attachment_definitions[:attachment][:styles] =
    format_styles(Spree::Image.attachment_definitions[:attachment][:styles])
end

Spree.config do |config|
  config.shipping_instructions = true
  config.address_requires_state = true
  config.admin_interface_logo = '/default_images/ofn-logo.png'

  # -- spree_paypal_express
  # Auto-capture payments. Without this option, payments must be manually captured in the paypal interface.
  config.auto_capture = true
  #config.override_actionmailer_config = false

  # S3 settings
  config.s3_bucket = ENV['S3_BUCKET'] if ENV['S3_BUCKET']
  config.s3_access_key = ENV['S3_ACCESS_KEY'] if ENV['S3_ACCESS_KEY']
  config.s3_secret = ENV['S3_SECRET'] if ENV['S3_SECRET']
  config.use_s3 = true if ENV['S3_BUCKET']
  config.s3_headers = ENV['S3_HEADERS'] if ENV['S3_HEADERS']
  config.s3_protocol = ENV.fetch('S3_PROTOCOL', 'https')

  # Attachments settings
  config.attachment_default_url = ENV['ATTACHMENT_DEFAULT_URL'] if ENV['ATTACHMENT_DEFAULT_URL']
  config.attachment_path = ENV['ATTACHMENT_PATH'] if ENV['ATTACHMENT_PATH']
  config.attachment_url = ENV['ATTACHMENT_URL'] if ENV['ATTACHMENT_URL']
  config.attachment_styles = ENV['ATTACHMENT_STYLES'] if ENV['ATTACHMENT_STYLES']
  config.attachment_default_style = ENV['ATTACHMENT_DEFAULT_STYLE'] if ENV['ATTACHMENT_DEFAULT_STYLE']

  # Update paperclip settings
  if config.use_s3
    s3_creds = { access_key_id: config.s3_access_key,
                 secret_access_key: config.s3_secret,
                 bucket: config.s3_bucket }
    Spree::Image.attachment_definitions[:attachment][:storage] = :s3
    Spree::Image.attachment_definitions[:attachment][:s3_credentials] = s3_creds
    Spree::Image.attachment_definitions[:attachment][:s3_headers] =
      ActiveSupport::JSON.decode(config.s3_headers)
    Spree::Image.attachment_definitions[:attachment][:bucket] = config.s3_bucket
  else
    Spree::Image.attachment_definitions[:attachment].delete :storage
  end

  Spree::Image.attachment_definitions[:attachment][:styles] =
    ActiveSupport::JSON.decode(config.attachment_styles).symbolize_keys!
  Spree::Image.attachment_definitions[:attachment][:path] = config.attachment_path
  Spree::Image.attachment_definitions[:attachment][:default_url] =
    config.attachment_default_url
  Spree::Image.attachment_definitions[:attachment][:default_style] =
    config.attachment_default_style

  reformat_styles
end

# Spree 2.0 recommends explicitly setting this here when using spree_auth_devise
Spree.user_class = 'Spree::User'

# TODO Work out why this is necessary
# Seems like classes within OFN module become 'uninitialized' when server reloads
# unless the empty module is explicity 'registered' here. Something to do with autoloading?
module OpenFoodNetwork
end
