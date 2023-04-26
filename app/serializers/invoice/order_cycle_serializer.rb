# frozen_string_literal: false

class Invoice
  class OrderCycleSerializer < ActiveModel::Serializer
    attributes :name
  end
end
