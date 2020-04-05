Spree::AppConfiguration.class_eval do
  # This file decorates the existing preferences file defined by Spree.
  # It allows us to add our own global configuration variables, which
  # we can allow to be modified in the UI by adding appropriate form
  # elements to existing or new configuration pages.

  # Preferences related to image settings
  preference :attachment_default_url, :string, default: '/spree/products/:id/:style/:basename.:extension'
  preference :attachment_path, :string, default: ':rails_root/public/spree/products/:id/:style/:basename.:extension'
  preference :attachment_url, :string, default: '/spree/products/:id/:style/:basename.:extension'
  preference :attachment_styles, :string, default: "{\"mini\":\"48x48>\",\"small\":\"100x100>\",\"product\":\"240x240>\",\"large\":\"600x600>\"}"
  preference :attachment_default_style, :string, default: 'product'
  preference :s3_access_key, :string
  preference :s3_bucket, :string
  preference :s3_secret, :string
  preference :s3_headers, :string, default: "{\"Cache-Control\":\"max-age=31557600\"}"
  preference :use_s3, :boolean, default: false # Use S3 for images rather than the file system
  preference :s3_protocol, :string
  preference :s3_host_alias, :string

  # Embedded Shopfronts
  preference :enable_embedded_shopfronts, :boolean, default: false
  preference :embedded_shopfronts_whitelist, :text, default: nil

  # Legal Preferences
  preference :footer_tos_url, :string, default: "/Terms-of-service.pdf"
  preference :enterprises_require_tos, :boolean, default: false
  preference :privacy_policy_url, :string, default: nil
  preference :cookies_consent_banner_toggle, :boolean, default: false
  preference :cookies_policy_matomo_section, :boolean, default: false
  preference :cookies_policy_ga_section, :boolean, default: false

  # Tax Preferences
  preference :products_require_tax_category, :boolean, default: false
  preference :shipping_tax_rate, :decimal, default: 0

  # Monitoring
  preference :last_job_queue_heartbeat_at, :string, default: nil

  # External services
  preference :bugherd_api_key, :string, default: nil
  preference :matomo_url, :string, default: nil
  preference :matomo_site_id, :string, default: nil

  # Invoices & Receipts
  preference :enable_invoices?, :boolean, default: true
  preference :invoice_style2?, :boolean, default: false
  preference :enable_receipt_printing?, :boolean, default: false

  # Stripe Connect
  preference :stripe_connect_enabled, :boolean, default: false

  # Number localization
  preference :enable_localized_number?, :boolean, default: false

  # Enable cache
  preference :enable_products_cache?, :boolean, default: (Rails.env.production? || Rails.env.staging?)
end
