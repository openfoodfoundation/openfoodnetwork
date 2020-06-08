# frozen_string_literal: true

module Api
  class OpenStreetMapConfigSerializer < ActiveModel::Serializer
    attributes :open_street_map_enabled,
               :open_street_map_provider_name,
               :open_street_map_provider_options

    def open_street_map_enabled
      ContentConfig.open_street_map_enabled
    end

    def open_street_map_provider_name
      ContentConfig.open_street_map_provider_name
    end

    def open_street_map_provider_options
      ContentConfig.open_street_map_provider_options.to_json
    end
  end
end
