require 'spree/core/controller_helpers/respond_with_decorator'
require 'open_food_network/tag_rule_applicator'

class BaseController < ApplicationController
  include Spree::Core::ControllerHelpers
  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::RespondWith

  include EnterprisesHelper
  include OrderCyclesHelper

  helper 'spree/base'

  # Spree::Core::ControllerHelpers declares helper_method get_taxonomies, so we need to
  # include Spree::ProductsHelper so that method is available on the controller
  include Spree::ProductsHelper

  before_filter :check_order_cycle_expiry


  private

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active
    .order(@distributor.preferred_shopfront_order_cycle_order)

    applicator = OpenFoodNetwork::TagRuleApplicator.new(@distributor, "FilterOrderCycles", current_customer.andand.tag_list)
    applicator.filter!(@order_cycles)

    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
