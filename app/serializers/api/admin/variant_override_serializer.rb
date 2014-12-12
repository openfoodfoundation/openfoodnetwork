class Api::Admin::VariantOverrideSerializer < ActiveModel::Serializer
  attributes :id, :hub_id, :variant_id, :price, :count_on_hand
end
