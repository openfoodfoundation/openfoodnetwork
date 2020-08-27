# frozen_string_literal: true

module Api
  class OpenStreetMapConfigSerializer < ActiveModel::Serializer
    attributes :open_street_map_enabled,
               :open_street_map_provider_name,
               :open_street_map_provider_options,
               :open_street_map_default_latitude,
               :open_street_map_default_longitude

    def open_street_map_enabled
      ContentConfig.open_street_map_enabled
    end

    def open_street_map_provider_name
      ContentConfig.open_street_map_provider_name
    end

    def open_street_map_provider_options
      ContentConfig.open_street_map_provider_options
    end

    def open_street_map_default_latitude
      ContentConfig.open_street_map_default_latitude
    end

    def open_street_map_default_longitude
      ContentConfig.open_street_map_default_longitude
    end
  end
end
