class BaseController < ApplicationController
  include Spree::Core::ControllerHelpers
  include Spree::Core::ControllerHelpers::RespondWith
  include EnterprisesHelper
  include OrderCyclesHelper

  helper 'spree/base'

  # Spree::Core::ControllerHelpers declares helper_method get_taxonomies, so we need to
  # include Spree::ProductsHelper so that method is available on the controller
  include Spree::ProductsHelper

  before_filter :check_order_cycle_expiry

  def load_active_distributors
    @active_distributors ||= Enterprise.distributors_with_active_order_cycles
  end

  private

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active

    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
