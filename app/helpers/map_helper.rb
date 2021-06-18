# frozen_string_literal: true

module MapHelper
  def using_google_maps?
    ENV["GOOGLE_MAPS_API_KEY"].present? || google_maps_configured_with_geocoder_api_key?
  end

  private

  def google_maps_configured_with_geocoder_api_key?
    ENV["GEOCODER_API_KEY"].present? && (
      ENV["GEOCODER_SERVICE"].to_s == "google" || ENV["GEOCODER_SERVICE"].blank?
    )
  end
end
