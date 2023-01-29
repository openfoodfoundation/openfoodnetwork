# frozen_string_literal: true

require 'spree/core/controller_helpers/order'
require 'open_food_network/tag_rule_applicator'

class BaseController < ApplicationController
  layout 'darkswarm'

  include Spree::Core::ControllerHelpers::Order

  include I18nHelper
  include OrderCyclesHelper

  before_action :set_locale

  private

  def set_order_cycles
    @order_cycles = Shop::OrderCyclesList.ready_for_checkout_for(@distributor, current_customer)

    set_order_cycle
  end

  # Default to the only order cycle if there's only one
  def set_order_cycle
    return if @order_cycles.count != 1

    current_order(true).set_order_cycle! @order_cycles.first
  end
end
