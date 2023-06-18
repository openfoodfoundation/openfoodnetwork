# frozen_string_literal: false

class Invoice
  class StateSerializer < ActiveModel::Serializer
    attributes :name
  end
end
