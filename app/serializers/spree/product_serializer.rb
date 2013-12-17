module Spree
  class ProductSerializer < ActiveModel::Serializer
    attributes :id, :name, :description

    has_one :master
  end
end
