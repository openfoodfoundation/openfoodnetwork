class Api::VariantSerializer < ActiveModel::Serializer
  def serializable_hash
    cached_serializer_hash.merge uncached_serializer_hash
  end

  private
  
  def cached_serializer_hash
    Api::CachedVariantSerializer.new(object, @options).serializable_hash
  end

  def uncached_serializer_hash
    Api::UncachedVariantSerializer.new(object, @options).serializable_hash
  end
end

class Api::UncachedVariantSerializer < ActiveModel::Serializer
  attributes :price

  def price
    object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
  end
end

class Api::CachedVariantSerializer < ActiveModel::Serializer
  cached
  delegate :cache_key, to: :object

  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display, :on_demand
  has_many :images, serializer: Api::TaxonImageSerializer
end
