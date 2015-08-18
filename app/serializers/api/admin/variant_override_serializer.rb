class Api::Admin::VariantOverrideSerializer < ActiveModel::Serializer
  attributes :id, :hub_id, :variant_id, :sku, :price, :count_on_hand, :on_demand, :default_stock
end
