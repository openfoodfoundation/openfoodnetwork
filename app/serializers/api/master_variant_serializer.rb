class Api::MasterVariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display, :count_on_hand, :on_demand
  has_many :images, serializer: Api::TaxonImageSerializer
end
