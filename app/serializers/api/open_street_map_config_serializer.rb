# frozen_string_literal: true

module Api
  class OpenStreetMapConfigSerializer < ActiveModel::Serializer
    attributes :open_street_map_enabled,
               :open_street_map_provider_name,
               :open_street_map_provider_options,
               :open_street_map_default_latitude,
               :open_street_map_default_longitude

    delegate :open_street_map_enabled, to: :ContentConfig

    delegate :open_street_map_provider_name, to: :ContentConfig

    delegate :open_street_map_provider_options, to: :ContentConfig

    delegate :open_street_map_default_latitude, to: :ContentConfig

    delegate :open_street_map_default_longitude, to: :ContentConfig
  end
end
