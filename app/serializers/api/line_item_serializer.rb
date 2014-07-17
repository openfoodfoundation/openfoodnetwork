class Api::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :variant_id, :quantity, :price 
end
