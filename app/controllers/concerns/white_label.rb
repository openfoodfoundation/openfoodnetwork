# frozen_string_literal: true

module WhiteLabel
  extend ActiveSupport::Concern
  include EnterprisesHelper

  def hide_ofn_navigation(distributor = current_distributor)
    # if the distributor has the hide_ofn_navigation preference set to true
    # then we should hide the OFN navigation
    @hide_ofn_navigation = distributor.hide_ofn_navigation

    # if the distributor has the hide_ofn_navigation preference
    # set to false, there is no need to check the white_label_logo preference
    return unless @hide_ofn_navigation

    @white_label_logo = distributor.white_label_logo
    @white_label_distributor = distributor
  end
end
