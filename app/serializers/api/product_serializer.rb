class Api::ProductSerializer < ActiveModel::Serializer
  # TODO
  # Prices can't be cached? How?
  
  cached
  delegate :cache_key, to: :object

  attributes :id, :name, :permalink, :count_on_hand, :on_demand, :group_buy,
    :notes, :description, :price

  has_many :variants, serializer: Api::VariantSerializer
  has_many :taxons, serializer: Api::IdSerializer
  has_many :properties, serializer: Api::PropertySerializer

  has_one :supplier, serializer: Api::IdSerializer
  has_one :primary_taxon, serializer: Api::TaxonSerializer
  has_one :master, serializer: Api::MasterVariantSerializer

  def price
    object.master.price_with_fees(options[:current_distributor], options[:current_order_cycle])
  end
end
