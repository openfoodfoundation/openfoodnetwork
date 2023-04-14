# frozen_string_literal: true

module WhiteLabel
  extend ActiveSupport::Concern
  include EnterprisesHelper

  def hide_ofn_navigation(distributor = current_distributor)
    # if the distributor has the hide_ofn_navigation preference set to true
    # then we should hide the OFN navigation
    @hide_ofn_navigation = distributor.hide_ofn_navigation
  end
end
