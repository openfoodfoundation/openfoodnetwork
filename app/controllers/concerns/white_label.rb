# frozen_string_literal: true

module WhiteLabel
  extend ActiveSupport::Concern
  include EnterprisesHelper

  def hide_ofn_navigation
    return false unless OpenFoodNetwork::FeatureToggle.enabled?(:white_label)

    # if the distributor has the hide_ofn_navigation preference set to true
    # then we should hide the OFN navigation
    @hide_ofn_navigation = distributor.preferred_hide_ofn_navigation
  end

  private

  def distributor
    return current_distributor unless request.path.start_with?("/orders/")

    # if we are on an order confirmation page,
    # we need to get the distributor from the order, not the current one
    Spree::Order.find_by(number: params[:id]).distributor
  end
end
