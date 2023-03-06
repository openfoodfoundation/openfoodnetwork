# frozen_string_literal: true

# This is the primary location for defining spree preferences
#
# This file allows us to add global configuration variables, which
# we can allow to be modified in the UI by adding appropriate form
# elements to existing or new configuration pages.
#
# The expectation is that this is created once and stored in
# the spree environment
#
# setters:
# a.color = :blue
# a[:color] = :blue
# a.set :color = :blue
# a.preferred_color = :blue
#
# getters:
# a.color
# a[:color]
# a.get :color
# a.preferred_color
#
require 'spree/core/mail_settings'

module Spree
  class AppConfiguration < Preferences::Configuration
    # Should state/state_name be required
    preference :address_requires_state, :boolean, default: true
    preference :admin_interface_logo, :string, default: '/default_images/ofn-logo.png'
    preference :admin_products_per_page, :integer, default: 10
    # Should only be true if you don't need to track inventory
    preference :allow_backorder_shipping, :boolean, default: false
    preference :allow_checkout_on_gateway_error, :boolean, default: false
    preference :allow_guest_checkout, :boolean, default: true
    # Replace with the name of a zone if you would like to limit the countries
    preference :checkout_zone, :string, default: nil
    preference :currency, :string, default: "USD"
    preference :currency_decimal_mark, :string, default: "."
    preference :currency_symbol_position, :string, default: "before"
    preference :currency_thousands_separator, :string, default: ","
    preference :display_currency, :boolean, default: false
    preference :default_country_id, :integer
    preference :default_meta_description, :string, default: 'OFN demo site'
    preference :default_meta_keywords, :string, default: 'ofn, demo'
    preference :default_seo_title, :string, default: ''
    preference :hide_cents, :boolean, default: false
    preference :layout, :string, default: 'darkswarm'
    preference :logo, :string, default: '/default_images/ofn-logo.png'

    # Maximum nesting level in taxons menu
    preference :max_level_in_taxons_menu, :integer, default: 1
    preference :orders_per_page, :integer, default: 15
    preference :prices_inc_tax, :boolean, default: false
    preference :products_per_page, :integer, default: 12
    preference :redirect_https_to_http, :boolean, default: false
    preference :require_master_price, :boolean, default: true
    # Request instructions/info for shipping
    preference :shipping_instructions, :boolean, default: false
    # Displays variant full price or difference with product price.
    preference :show_variant_full_price, :boolean, default: false
    preference :show_products_without_price, :boolean, default: false
    preference :show_raw_product_description, :boolean, default: false
    preference :site_name, :string, default: 'OFN Demo Site'
    preference :site_url, :string, default: 'demo.openfoodnetwork.org'
    preference :tax_using_ship_address, :boolean, default: true
    # Determines whether to track on_hand values for variants / products.
    preference :track_inventory_levels, :boolean, default: true

    # Preferences related to image settings
    preference :attachment_default_url, :string,
               default: '/spree/products/:id/:style/:basename.:extension'
    preference :attachment_path, :string,
               default: ':rails_root/public/spree/products/:id/:style/:basename.:extension'
    preference :attachment_url, :string,
               default: '/spree/products/:id/:style/:basename.:extension'
    preference :attachment_styles, :string,
               default: "{\"mini\":\"48x48>\",\"small\":\"100x100>\",\"product\":\"240x240>\",\"large\":\"600x600>\"}"
    preference :attachment_default_style, :string, default: 'product'
    preference :s3_access_key, :string
    preference :s3_bucket, :string
    preference :s3_secret, :string
    preference :s3_headers, :string, default: "{\"Cache-Control\":\"max-age=31557600\"}"
    preference :use_s3, :boolean, default: false # Use S3 for images rather than the file system
    preference :s3_protocol, :string
    preference :s3_host_alias, :string

    # Default mail headers settings
    preference :mails_from, :string, default: 'ofn@example.com'
    preference :mail_bcc, :string, default: 'ofn@example.com'
    preference :intercept_email, :string, default: nil

    # Default smtp settings
    preference :mail_host, :string, default: 'localhost'
    preference :mail_domain, :string, default: 'localhost'
    preference :mail_port, :integer, default: 25
    preference :secure_connection_type, :string,
               default: Core::MailSettings::SECURE_CONNECTION_TYPES[0]
    preference :mail_auth_type, :string, default: Core::MailSettings::MAIL_AUTH[0]
    preference :smtp_username, :string
    preference :smtp_password, :string

    # Embedded Shopfronts
    preference :enable_embedded_shopfronts, :boolean, default: false
    preference :embedded_shopfronts_whitelist, :text, default: nil

    # Legal Preferences
    preference :footer_tos_url, :string, default: "/Terms-of-service.pdf"
    preference :enterprises_require_tos, :boolean, default: false
    preference :shoppers_require_tos, :boolean, default: false
    preference :privacy_policy_url, :string, default: nil
    preference :cookies_consent_banner_toggle, :boolean, default: false
    preference :cookies_policy_matomo_section, :boolean, default: false

    # Tax Preferences
    preference :products_require_tax_category, :boolean, default: false

    # Monitoring
    preference :last_job_queue_heartbeat_at, :string, default: nil

    # External services
    preference :matomo_url, :string, default: nil
    preference :matomo_site_id, :string, default: nil
    preference :matomo_tag_manager_url, :string, default: nil

    # Invoices
    preference :enable_invoices?, :boolean, default: true
    preference :invoice_style2?, :boolean, default: false
    preference :enterprise_number_required_on_invoices?, :boolean, default: true

    # Stripe payments
    preference :stripe_connect_enabled, :boolean, default: false

    # Number localization
    preference :enable_localized_number?, :boolean, default: false

    # Enable cache
    preference :enable_products_cache?, :boolean,
               default: (Rails.env.production? || Rails.env.staging?)

    # Available units
    preference :available_units, :string, default: "g,kg,T,mL,L,kL"
  end
end
