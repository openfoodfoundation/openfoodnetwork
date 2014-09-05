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

  def orders_close_at
    OrderCycle.first_closing_for(object).andand.orders_close_at
  end

  def active
    @options[:active_distributors].andand.include? object
  end
end

class Api::CachedEnterpriseSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :name, :id, :description, :latitude, :longitude,
    :long_description, :website, :instagram, :linkedin, :twitter,
    :facebook, :is_primary_producer, :is_distributor, :phone, :visible,
    :email, :hash, :logo, :promo_image, :icon, :path,
    :pickup, :delivery
  attributes :has_shopfront, :can_aggregate

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

  def icon
    if has_shopfront
      if can_aggregate
        "/assets/map_005-hub.svg"
      else
        if object.is_distributor
          "/assets/map_003-producer-shop.svg"
        else
          "/assets/map_001-producer-only.svg"
        end
      end
    else
      if can_aggregate
        "/assets/map_006-hub-profile.svg"
      else
        if object.is_distributor
          "/assets/map_004-producer-shop-profile.svg"
        else
          "/assets/map_002-producer-only-profile.svg"
        end
      end
    end
  end

  # TODO: Remove this when flags on enterprises are switched over
  def has_shopfront
    object.type != 'profile'
  end

  # TODO: Remove this when flags on enterprises are switched over
  def can_aggregate
    object.is_distributor && object.suppliers != [object]
  end

  # TODO when ActiveSerializers supports URL helpers
  # Then refactor. See readme https://github.com/rails-api/active_model_serializers
  def path
    "/enterprises/#{object.to_param}/shop"
  end
end
