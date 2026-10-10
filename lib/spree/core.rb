# frozen_string_literal: true

require 'active_merchant'
require 'acts_as_list'
require 'cancan'
require 'pagy'
require 'mail'
require 'paranoia'
require 'ransack'
require 'state_machines'

module Spree
  # Used to configure Spree.
  #
  # Example:
  #
  #   Spree.config do |config|
  #     config.site_name = "An awesome Spree site"
  #   end
  #
  # This method is defined within the core gem on purpose.
  # Some people may only wish to use the Core part of Spree.
  def self.config
    yield(Spree::Config)
  end

  # Spree models live in the `spree_` tables, e.g. Spree::Order uses `spree_orders`.
  def self.table_name_prefix
    "spree_"
  end

  # Model names are relative to this namespace, e.g. Spree::Order has the
  # param key `order` and routes like `order_path`.
  def self.use_relative_model_naming?
    true
  end
end

require 'spree/i18n'
require 'spree/money'

require 'spree/core/permalinks'
require 'spree/core/token_resource'
require 'spree/core/product_duplicator'
require 'spree/core/gateway_error'
