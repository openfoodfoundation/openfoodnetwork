# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'


require 'spree/product_filters'
require 'open_food_network/searcher'

Spree.config do |config|
  config.shipping_instructions = true
  config.checkout_zone = 'Australia'
  config.address_requires_state = true
  config.searcher_class = OpenFoodNetwork::Searcher

  # 109 should be Australia. Hardcoded for CI (Jenkins), where countries are not pre-loaded.
  config.default_country_id = Spree::Country.table_exists? && Spree::Country.find_by_name('Australia').andand.id
  config.default_country_id = 109 unless config.default_country_id.present? && config.default_country_id > 0

  # -- spree_paypal_express
  # Auto-capture payments. Without this option, payments must be manually captured in the paypal interface.
  config.auto_capture = true
end


# Add calculators category for enterprise fees
module Spree
  module Core
    class Environment
      class Calculators
        include EnvironmentExtension

        attr_accessor :enterprise_fees
      end
    end
  end
end
