# frozen_string_literal: false

class Invoice
  class AdjustmentSerializer < ActiveModel::Serializer
    attributes :adjustable_type, :label, :included_tax_total, :additional_tax_total, :amount,
               :currency
  end
end
