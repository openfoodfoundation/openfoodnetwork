class Api::Admin::InventoryItemSerializer < ActiveModel::Serializer
  attributes :id, :enterprise_id, :variant_id, :visible
end
