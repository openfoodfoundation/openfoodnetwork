# frozen_string_literal: true

# Represents the minimum details of an Enterprise when all shopfronts are being listed
module Api
  class EnterpriseShopfrontListSerializer < ActiveModel::Serializer
    attributes :name, :id, :latitude, :longitude, :is_primary_producer, :is_distributor,
               :path, :icon, :icon_font, :producer_icon_font, :address_id, :sells,
               :permalink

    has_one :address, serializer: Api::AddressSerializer

    def path
      enterprise_shop_path(enterprise)
    end

    def icon
      icons = {
        hub: "map_005-hub.svg",
        hub_profile: "map_006-hub-profile.svg",
        producer_hub: "map_005-hub.svg",
        producer_shop: "map_003-producer-shop.svg",
        producer: "map_001-producer-only.svg",
      }
      "/map_icons/" + (icons[enterprise.category] || "map_001-producer-only.svg")
    end

    def icon_font
      icon_fonts = {
        hub: "ofn-i_063-hub",
        hub_profile: "ofn-i_064-hub-reversed",
        producer_hub: "ofn-i_063-hub",
        producer_shop: "ofn-i_059-producer",
        producer: "ofn-i_059-producer",
      }
      icon_fonts[enterprise.category]
    end

    def producer_icon_font
      icon_fonts = {
        hub: "",
        hub_profile: "",
        producer_hub: "ofn-i_059-producer",
        producer_shop: "ofn-i_059-producer",
        producer: "ofn-i_059-producer",
      }
      icon_fonts[enterprise.category]
    end

    private

    def enterprise
      object
    end
  end
end
