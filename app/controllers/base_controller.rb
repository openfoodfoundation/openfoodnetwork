require 'spree/core/controller_helpers/auth'
require 'spree/core/controller_helpers/common'
require 'spree/core/controller_helpers/order'
require 'spree/core/controller_helpers/respond_with'
require 'open_food_network/tag_rule_applicator'

class BaseController < ApplicationController
  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::RespondWith

  include I18nHelper
  include EnterprisesHelper
  include OrderCyclesHelper

  helper 'spree/base'

  before_action :set_locale
  before_action :check_order_cycle_expiry

  private

  def set_order_cycles
    unless @distributor.ready_for_checkout?
      @order_cycles = OrderCycle.where('false')
      return
    end

    @order_cycles = Shop::OrderCyclesList.new(@distributor, current_customer).call

    set_order_cycle
  end

  # Default to the only order cycle if there's only one
  #
  # Here we need to use @order_cycles.size not @order_cycles.count
  #   because OrderCyclesList returns a modified ActiveRecord::Relation
  #     and these modifications are not seen if it is reloaded with count
  def set_order_cycle
    return if @order_cycles.size != 1

    current_order(true).set_order_cycle! @order_cycles.first
  end
end
