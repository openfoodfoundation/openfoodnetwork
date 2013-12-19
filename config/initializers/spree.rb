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

  # 12 should be Australia. Hardcoded for CI (Jenkins), where countries are not pre-loaded.
  config.default_country_id = 12

  # -- spree_paypal_express
  # Auto-capture payments. Without this option, payments must be manually captured in the paypal interface.
  config.auto_capture = true
  #config.override_actionmailer_config = false
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

# Forcing spree to always allow SSL connections
# Since we are using config.force_ssl = true 
# Without this we get a redirect loop: see https://groups.google.com/forum/#!topic/spree-user/NwpqGxJ4klk
SslRequirement.module_eval do
  protected

  def ssl_allowed?
    true
  end
end
