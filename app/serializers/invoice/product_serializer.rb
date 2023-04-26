# frozen_string_literal: false

class Invoice
  class ProductSerializer < ActiveModel::Serializer
    attributes :name
    has_one :supplier, serializer: Invoice::EnterpriseSerializer
  end
end
