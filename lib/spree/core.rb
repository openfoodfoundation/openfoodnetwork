# frozen_string_literal: true

require 'active_merchant'
require 'acts_as_list'
require 'awesome_nested_set'
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
end

require 'spree/core/engine'

require 'spree/i18n'
require 'spree/money'

require 'spree/core/delegate_belongs_to'
require 'spree/core/permalinks'
require 'spree/core/token_resource'
require 'spree/core/product_duplicator'
require 'spree/core/gateway_error'

ActiveRecord::Base.class_eval do
  include CollectiveIdea::Acts::NestedSet
end
