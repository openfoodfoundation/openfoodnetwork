# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'

ActiveRecord::Base.include Spree::Preferences::Preferable

Rails.application.config.spree = Spree::Core::Environment.new
Spree::Config = Rails.application.config.spree.preferences # legacy access

require 'spree/core'

Rails.application.config do |app|
  app.config.spree.payment_methods = [
    Spree::Gateway::Bogus,
    Spree::Gateway::BogusSimple,
    Spree::PaymentMethod::Check,
    Spree::Gateway::StripeConnect,
    Spree::Gateway::StripeSCA,
    Spree::Gateway::PayPalExpress
  ]

  Spree::Core::MailSettings.init
  Mail.register_interceptor(Spree::Core::MailInterceptor)

  # filter sensitive information during logging
  app.config.filter_parameters += [
    :password,
    :password_confirmation,
    :number,
    :verification_value
  ]

  Spree::Config['checkout_zone'] = ENV['CHECKOUT_ZONE']
  Spree::Config['currency'] = ENV['CURRENCY']
  if Spree::Country.table_exists?
    country = Spree::Country.find_by(iso: ENV['DEFAULT_COUNTRY_CODE'])
    Spree::Config['default_country_id'] = country.id if country.present?
  else
    Spree::Config['default_country_id'] = 12  # Australia
  end

  app.config.spree.calculators.shipping_methods = [
    Calculator::FlatPercentItemTotal,
    Calculator::FlatRate,
    Calculator::FlexiRate,
    Calculator::PerItem,
    Calculator::PriceSack,
    Calculator::Weight
  ]

  app.config.spree.calculators.add_class('enterprise_fees')
  config.spree.calculators.enterprise_fees = [
    Calculator::FlatPercentPerItem,
    Calculator::FlatRate,
    Calculator::FlexiRate,
    Calculator::PerItem,
    Calculator::PriceSack,
    Calculator::Weight
  ]

  app.config.spree.calculators.add_class('payment_methods')
  config.spree.calculators.payment_methods = [
    Calculator::FlatPercentItemTotal,
    Calculator::FlatRate,
    Calculator::FlexiRate,
    Calculator::PerItem,
    Calculator::PriceSack
  ]

  app.config.spree.calculators.add_class('tax_rates')
  config.spree.calculators.tax_rates = [
    Calculator::DefaultTax
  ]
end

# Due to a bug in ActiveRecord we need to load the tagging code in Gateway which
# should have inherited it from its parent PaymentMethod.
# We have to call it before loading the PaymentMethod decorator because the
# tagging code won't load twice within the inheritance chain.
# https://github.com/openfoodfoundation/openfoodnetwork/issues/3121
Spree::Gateway.class_eval do
  acts_as_taggable
end

Spree.config do |config|
  config.shipping_instructions = true
  config.address_requires_state = true
  config.admin_interface_logo = '/default_images/ofn-logo.png'

  # -- spree_paypal_express
  # Auto-capture payments. Without this option, payments must be manually captured in the paypal interface.
  config.auto_capture = true

  # S3 settings
  config.s3_bucket = ENV['S3_BUCKET'] if ENV['S3_BUCKET']
  config.s3_access_key = ENV['S3_ACCESS_KEY'] if ENV['S3_ACCESS_KEY']
  config.s3_secret = ENV['S3_SECRET'] if ENV['S3_SECRET']
  config.use_s3 = true if ENV['S3_BUCKET']
  config.s3_headers = ENV['S3_HEADERS'] if ENV['S3_HEADERS']
  config.s3_protocol = ENV.fetch('S3_PROTOCOL', 'https')
end

# Attachments settings
Spree::Image.set_attachment_attribute(:path, ENV['ATTACHMENT_PATH']) if ENV['ATTACHMENT_PATH']
Spree::Image.set_attachment_attribute(:url, ENV['ATTACHMENT_URL']) if ENV['ATTACHMENT_URL']
Spree::Image.set_storage_attachment_attributes

# Spree 2.0 recommends explicitly setting this here when using spree_auth_devise
Spree.user_class = 'Spree::User'

# TODO Work out why this is necessary
# Seems like classes within OFN module become 'uninitialized' when server reloads
# unless the empty module is explicity 'registered' here. Something to do with autoloading?
module OpenFoodNetwork
end
