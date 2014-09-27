class Api::EnterpriseSerializer < ActiveModel::Serializer
  def serializable_hash
    cached_serializer_hash.merge uncached_serializer_hash
  end

  private

  def cached_serializer_hash
    Api::CachedEnterpriseSerializer.new(object, @options).serializable_hash
  end

  def uncached_serializer_hash
    Api::UncachedEnterpriseSerializer.new(object, @options).serializable_hash
  end
end

class Api::UncachedEnterpriseSerializer < ActiveModel::Serializer
  attributes :orders_close_at, :active

  attributes :icon, :icon_font, :producer_icon_font, :has_shopfront, :has_hub_listing, :enterprise_category, :is_distributor

  def orders_close_at
    OrderCycle.first_closing_for(object).andand.orders_close_at
  end

  def active
    @options[:active_distributors].andand.include? object
  end

  def enterprise_category
    object.enterprise_category
  end

  def has_shopfront
    object.is_distributor
  end

  def is_distributor
    object.is_distributor
  end

  # Used to select enterprises for hub listing
  def has_hub_listing
    object.is_distributor || object.enterprise_category == "hub_profile"
  end

  # Map svg icons.
  def icon
    icons = {
      "hub" => "/assets/map_005-hub.svg",
      "hub_profile" => "/assets/map_006-hub-profile.svg",
      "producer_hub" => "/assets/map_005-hub.svg",
      "producer_shop" => "/assets/map_003-producer-shop.svg",
      "producer" => "/assets/map_001-producer-only.svg",
      "producer_profile" => "/assets/map_002-producer-only-profile.svg",
    }
    icons[object.enterprise_category]
  end

  # Choose regular icon font for enterprises.
  def icon_font
    icon_fonts = {
      "hub" => "ofn-i_063-hub",
      "hub_profile" => "ofn-i_064-hub-reversed",
      "producer_hub" => "ofn-i_063-hub",
      "producer_shop" => "ofn-i_059-producer",
      "producer" => "ofn-i_059-producer",
      "producer_profile" => "ofn-i_060-producer-reversed",
    }
    icon_fonts[object.enterprise_category]
  end

  # Choose producer page icon font - yes, sadly its got to be different.
  # This duplicates some code but covers the producer page edge case where
  # producer-hub has a producer icon without needing to duplicate the category logic in angular.
  def producer_icon_font
    icon_fonts = {
      "hub" => "",
      "hub_profile" => "",
      "producer_hub" => "ofn-i_059-producer",
      "producer_shop" => "ofn-i_059-producer",
      "producer" => "ofn-i_059-producer",
      "producer_profile" => "ofn-i_060-producer-reversed",
      "empty" => "",
    }
    icon_fonts[object.enterprise_category]
  end

end

class Api::CachedEnterpriseSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :name, :id, :description, :latitude, :longitude,
    :long_description, :website, :instagram, :linkedin, :twitter,
    :facebook, :is_primary_producer, :is_distributor, :phone, :visible,
    :email, :hash, :logo, :promo_image, :path,
    :pickup, :delivery

  has_many :distributed_taxons, key: :taxons, serializer: Api::IdSerializer
  has_many :supplied_taxons, serializer: Api::IdSerializer
  has_many :distributors, key: :hubs, serializer: Api::IdSerializer
  has_many :suppliers, key: :producers, serializer: Api::IdSerializer

  has_one :address, serializer: Api::AddressSerializer

  def pickup
    object.shipping_methods.where(:require_ship_address => false).present?
  end

  def delivery
    object.shipping_methods.where(:require_ship_address => true).present?
  end

  def email
    object.email.to_s.reverse
  end

  def hash
    object.to_param
  end

  def logo
    object.logo(:medium) if object.logo.exists?
  end

  def promo_image
    object.promo_image(:large) if object.promo_image.exists?
  end

  # TODO when ActiveSerializers supports URL helpers
  # Then refactor. See readme https://github.com/rails-api/active_model_serializers
  def path
    "/enterprises/#{object.to_param}/shop"
  end
end
