class BaseController < ApplicationController
  include Spree::Core::ControllerHelpers
  include Spree::Core::ControllerHelpers::RespondWith
  include OrderCyclesHelper

  helper 'spree/base'

  # Spree::Core::ControllerHelpers declares helper_method get_taxonomies, so we need to
  # include Spree::ProductsHelper so that method is available on the controller
  include Spree::ProductsHelper

  before_filter :check_order_cycle_expiry
end
