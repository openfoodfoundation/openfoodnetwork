# frozen_string_literal: false

class Invoice
  class TaxRateSerializer < ActiveModel::Serializer
    attributes :id, :amount
  end
end
