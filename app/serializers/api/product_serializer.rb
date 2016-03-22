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
    if options[:enterprise_fee_calculator]
      object.master.price + options[:enterprise_fee_calculator].indexed_fees_for(object.master)
    else
      object.master.price_with_fees(options[:current_distributor], options[:current_order_cycle])
    end

  end
end

class Api::CachedProductSerializer < ActiveModel::Serializer
  #cached
  #delegate :cache_key, to: :object
  include ActionView::Helpers::SanitizeHelper

  attributes :id, :name, :permalink, :count_on_hand
  attributes :on_demand, :group_buy, :notes, :description
  attributes :properties_with_values

  has_many :variants, serializer: Api::VariantSerializer
  has_one :master, serializer: Api::VariantSerializer

  has_one :primary_taxon, serializer: Api::TaxonSerializer
  has_many :taxons, serializer: Api::IdSerializer

  has_many :images, serializer: Api::ImageSerializer
  has_one :supplier, serializer: Api::IdSerializer

  def description
    strip_tags object.description
  end

  def properties_with_values
    object.properties_including_inherited
  end

  def variants
    options[:variants][object.id] || []
  end

  def master
    options[:master_variants][object.id].andand.first
  end

end
