require 'open_food_network/property_merge'

class Api::EnterpriseSerializer < ActiveModel::Serializer
  # We reference this here because otherwise the serializer complains about its absence
  Api::IdSerializer

  def serializable_hash
    cached_serializer_hash.merge uncached_serializer_hash
  end

  private

  def cached_serializer_hash
    Api::CachedEnterpriseSerializer.new(object, @options).serializable_hash || {}
  end

  def uncached_serializer_hash
    Api::UncachedEnterpriseSerializer.new(object, @options).serializable_hash || {}
  end
end

class Api::UncachedEnterpriseSerializer < ActiveModel::Serializer
  include SerializerHelper

  attributes :orders_close_at, :active

  def orders_close_at
    options[:data].earliest_closing_times[object.id]
  end

  def active
    options[:data].active_distributors.andand.include? object
  end
end

class Api::CachedEnterpriseSerializer < ActiveModel::Serializer
  include SerializerHelper

  cached
  #delegate :cache_key, to: :object

  def cache_key
    object.andand.cache_key
  end


  attributes :name, :id, :description, :latitude, :longitude,
    :long_description, :website, :instagram, :linkedin, :twitter,
    :facebook, :is_primary_producer, :is_distributor, :phone, :visible,
    :email_address, :hash, :logo, :promo_image, :path, :pickup, :delivery,
    :icon, :icon_font, :producer_icon_font, :category, :producers, :hubs

  attributes :taxons, :supplied_taxons

  has_one :address, serializer: Api::AddressSerializer

  has_many :supplied_properties, serializer: Api::PropertySerializer
  has_many :distributed_properties, serializer: Api::PropertySerializer

  def pickup
    services = options[:data].shipping_method_services[object.id]
    services ? services[:pickup] : false
  end

  def delivery
    services = options[:data].shipping_method_services[object.id]
    services ? services[:delivery] : false
  end

  def email_address
    object.email_address.to_s.reverse
  end

  def hash
    object.to_param
  end

  def logo
    object.logo(:medium) if object.logo?
  end

  def promo_image
    object.promo_image(:large) if object.promo_image?
  end

  def path
    enterprise_shop_path(object)
  end

  def producers
    relatives = options[:data].relatives[object.id]
    ids_to_objs(relatives.andand[:producers])
  end

  def hubs
    relatives = options[:data].relatives[object.id]
    ids_to_objs(relatives.andand[:distributors])
  end

  def taxons
    if active
      ids_to_objs options[:data].current_distributed_taxons[object.id]
    else
      ids_to_objs options[:data].all_distributed_taxons[object.id]
    end
  end

  def supplied_taxons
    ids_to_objs options[:data].supplied_taxons[object.id]
  end

  def supplied_properties
    # This results in 3 queries per enterprise
    product_properties  = Spree::Property.applied_by(object)
    producer_properties = object.properties

    OpenFoodNetwork::PropertyMerge.merge product_properties, producer_properties
  end

  def distributed_properties
    # This results in 3 queries per enterprise

    if active
      product_properties  = Spree::Property.currently_sold_by(object)
      producer_property_ids = ProducerProperty.currently_sold_by(object).pluck(:property_id)

    else
      product_properties  = Spree::Property.ever_sold_by(object)
      producer_property_ids = ProducerProperty.ever_sold_by(object).pluck(:property_id)
    end

    producer_properties = Spree::Property.where(id: producer_property_ids)

    OpenFoodNetwork::PropertyMerge.merge product_properties, producer_properties
  end

  def active
    options[:data].active_distributors.andand.include? object
  end

  # Map svg icons.
  def icon
    icons = {
      :hub => "/assets/map_005-hub.svg",
      :hub_profile => "/assets/map_006-hub-profile.svg",
      :producer_hub => "/assets/map_005-hub.svg",
      :producer_shop => "/assets/map_003-producer-shop.svg",
      :producer => "/assets/map_001-producer-only.svg",
    }
    icons[object.category]
  end

  # Choose regular icon font for enterprises.
  def icon_font
    icon_fonts = {
      :hub => "ofn-i_063-hub",
      :hub_profile => "ofn-i_064-hub-reversed",
      :producer_hub => "ofn-i_063-hub",
      :producer_shop => "ofn-i_059-producer",
      :producer => "ofn-i_059-producer",
    }
    icon_fonts[object.category]
  end

  # Choose producer page icon font - yes, sadly its got to be different.
  # This duplicates some code but covers the producer page edge case where
  # producer-hub has a producer icon without needing to duplicate the category logic in angular.
  def producer_icon_font
    icon_fonts = {
      :hub => "",
      :hub_profile => "",
      :producer_hub => "ofn-i_059-producer",
      :producer_shop => "ofn-i_059-producer",
      :producer => "ofn-i_059-producer",
    }
    icon_fonts[object.category]
  end
end
