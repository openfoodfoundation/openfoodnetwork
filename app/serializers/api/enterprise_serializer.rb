class Api::EnterpriseSerializer < ActiveModel::Serializer
  # To improve this: http://hawkins.io/2013/06/caching_object_graphs_with_active_model_serializers/
  
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
    @options[:active_distributors].andand.include?(object)
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

  has_many :distributed_taxons, key: :taxons, serializer: Api::IdSerializer
  has_many :supplied_taxons, serializer: Api::IdSerializer
  has_many :distributors, key: :hubs, serializer: Api::IdSerializer
  has_many :suppliers, key: :producers, serializer: Api::IdSerializer

  #has_one :address, serializer: Api::AddressSerializer

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
    if object.is_primary_producer? and object.is_distributor?
      "/assets/map-icon-both.svg"
    elsif object.is_primary_producer?
      "/assets/map-icon-producer.svg"
    else
      "/assets/map-icon-hub.svg"
    end
  end

  # TODO when ActiveSerializers supports URL helpers
  # Then refactor. See readme https://github.com/rails-api/active_model_serializers
  def path
    "/enterprises/#{object.to_param}/shop"
  end
end
