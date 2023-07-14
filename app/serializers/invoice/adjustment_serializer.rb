# frozen_string_literal: false

class Invoice
  class AdjustmentSerializer < ActiveModel::Serializer
    attributes :adjustable_type, :label, :included_tax_total, :additional_tax_total, :amount,
               :currency
    has_many :tax_rates, serializer: Invoice::TaxRateSerializer

    def tax_rates
      TaxRateFinder.tax_rates_of(object)
    end
  end
end
