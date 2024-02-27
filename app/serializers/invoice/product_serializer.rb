# frozen_string_literal: false

class Invoice
  class ProductSerializer < ActiveModel::Serializer
    attributes :name
  end
end
