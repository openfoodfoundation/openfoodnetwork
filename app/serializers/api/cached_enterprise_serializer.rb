# frozen_string_literal: true

require 'open_food_network/property_merge'

module Api
  class CachedEnterpriseSerializer < ActiveModel::Serializer
    include SerializerHelper

    cached

    def cache_key
      enterprise&.cache_key
    end

    attributes :name, :id, :description, :latitude, :longitude,
               :long_description, :website, :instagram, :linkedin, :twitter,
               :facebook, :is_primary_producer, :is_distributor, :phone, :whatsapp_phone,
               :whatsapp_url, :visible, :email_address, :hash, :logo, :promo_image, :path, :pickup,
               :delivery, :icon, :icon_font, :producer_icon_font, :category

    attributes :taxons, :supplied_taxons

    has_one :address, serializer: AddressSerializer

    has_many :supplied_properties, serializer: PropertySerializer
    has_many :distributed_properties, serializer: PropertySerializer

    def pickup
      services = data.shipping_method_services[enterprise.id]
      services ? services[:pickup] : false
    end

    def delivery
      services = data.shipping_method_services[enterprise.id]
      services ? services[:delivery] : false
    end

    def email_address
      enterprise.email_address.to_s.reverse
    end

    def hash
      enterprise.to_param
    end

    def logo
      enterprise.logo_url(:medium)
    end

    def promo_image
      enterprise.promo_image_url(:large)
    end

    def path
      enterprise_shop_path(enterprise)
    end

    def taxons
      if active
        ids_to_objs data.current_distributed_taxons[enterprise.id]
      else
        ids_to_objs data.all_distributed_taxons[enterprise.id]
      end
    end

    def supplied_taxons
      return [] unless enterprise.is_primary_producer

      ids_to_objs data.supplied_taxons[enterprise.id]
    end

    def supplied_properties
      return [] unless enterprise.is_primary_producer

      (product_properties + producer_properties).uniq do |property_object|
        property_object.property.presentation
      end
    end

    # This results in 3 queries per enterprise
    def distributed_properties
      return [] unless active

      (distributed_product_properties + distributed_producer_properties).uniq do |property_object|
        property_object.property.presentation
      end
    end

    def distributed_product_properties
      return [] unless active

      properties = Spree::Property
        .joins(products: { variants: { exchanges: :order_cycle } })
        .merge(Exchange.outgoing)
        .merge(Exchange.to_enterprise(enterprise))
        .select('DISTINCT spree_properties.*')

      return properties.merge(OrderCycle.active) if active

      properties
    end

    def distributed_producer_properties
      return [] unless active

      properties = Spree::Property
        .joins(
          producer_properties: {
            producer: { supplied_products: { variants: { exchanges: :order_cycle } } }
          }
        )
        .merge(Exchange.outgoing)
        .merge(Exchange.to_enterprise(enterprise))
        .select('DISTINCT spree_properties.*')

      return properties.merge(OrderCycle.active) if active

      properties
    end

    def active
      @active ||= data.active_distributor_ids&.include? enterprise.id
    end

    # Map svg icons.
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

    # Choose regular icon font for enterprises.
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

    # Choose producer page icon font - yes, sadly its got to be different.
    # This duplicates some code but covers the producer page edge case where
    # producer-hub has a producer icon without needing to duplicate the category logic in angular.
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

    def product_properties
      Spree::Property.joins(:product_properties).where(
        spree_product_properties: {
          product_id: enterprise.supplied_product_ids
        }
      ).select('DISTINCT spree_properties.*')
    end

    def producer_properties
      enterprise.properties
    end

    def enterprise
      object
    end

    def data
      options[:data]
    end
  end
end
