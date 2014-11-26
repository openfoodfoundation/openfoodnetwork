class Api::Admin::VariantOverrideSerializer < ActiveModel::Serializer
  attributes :id, :variant_id, :hub_id, :price, :count_on_hand
end
