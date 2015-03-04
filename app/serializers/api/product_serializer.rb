require 'open_food_network/scope_variant_to_hub'

class Api::ProductSerializer < ActiveModel::Serializer
  # TODO
  # Prices can't be cached? How?
  def serializable_hash
    cached_serializer_hash.merge uncached_serializer_hash
  end

  private

  def cached_serializer_hash
    Api::CachedProductSerializer.new(object, @options).serializable_hash
  end

  def uncached_serializer_hash
    Api::UncachedProductSerializer.new(object, @options).serializable_hash
  end
end

class Api::UncachedProductSerializer < ActiveModel::Serializer
  attributes :price

  def price
    object.master.price_with_fees(options[:current_distributor], options[:current_order_cycle])
  end
end

class Api::CachedProductSerializer < ActiveModel::Serializer
  #cached
  #delegate :cache_key, to: :object

  attributes :id, :name, :permalink, :count_on_hand, :on_demand, :group_buy,
    :notes, :description

  has_many :variants, serializer: Api::VariantSerializer
  has_many :taxons, serializer: Api::IdSerializer
  has_many :properties, serializer: Api::PropertySerializer
  has_many :images, serializer: Api::ImageSerializer

  has_one :supplier, serializer: Api::IdSerializer
  has_one :primary_taxon, serializer: Api::TaxonSerializer
  has_one :master, serializer: Api::VariantSerializer

  def variants
    # We use the in_stock? method here instead of the in_stock scope because we need to
    # look up the stock as overridden by VariantOverrides, and the scope method is not affected
    # by them.

    object.variants.
      for_distribution(options[:current_order_cycle], options[:current_distributor]).
      each { |v| v.scope_to_hub options[:current_distributor] }.
      select(&:in_stock?)
  end
end
