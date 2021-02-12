# frozen_string_literal: true

module GeocodeEnterpriseAddress
  extend ActiveSupport::Concern

  def geocode_address_if_use_geocoder
    AddressGeocoder.new(@enterprise.address).geocode if params[:use_geocoder] == "1"
  end
end
