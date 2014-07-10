class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display, :on_demand, :price
  has_many :images, serializer: Api::TaxonImageSerializer

  def price
    0.0
  end
end
