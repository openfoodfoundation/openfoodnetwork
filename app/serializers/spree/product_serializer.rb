module Spree
  class ProductSerializer < ActiveModel::Serializer
    attributes :id, :name, :description, :price
    has_one :master
    has_many :variants
  end
end
