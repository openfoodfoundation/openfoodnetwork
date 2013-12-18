module Spree
  class ProductSerializer < ActiveModel::Serializer
    attributes :id, :name, :description, :price, :permalink
    has_one :master
    has_one :supplier
    has_many :variants
  end
end
