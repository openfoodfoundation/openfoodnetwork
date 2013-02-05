class BaseController < ApplicationController
  include Spree::Core::ControllerHelpers
  include Spree::Core::ControllerHelpers::RespondWith

  helper 'spree/base'

  # Spree::Core::ControllerHelpers declares helper_method get_taxonomies, so we need to
  # include Spree::ProductsHelper so that method is available on the controller
  include Spree::ProductsHelper
end
