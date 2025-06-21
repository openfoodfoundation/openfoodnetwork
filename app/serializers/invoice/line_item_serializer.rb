# frozen_string_literal: false

class Invoice
  class LineItemSerializer < ActiveModel::Serializer
    attributes :id, :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
               :variant_id, :unit_price, :unit_presentation,
               :enterprise_fee_additional_tax, :enterprise_fee_included_tax
    has_one :variant, serializer: Invoice::VariantSerializer

    def enterprise_fee_additional_tax
      EnterpriseFeeAdjustments.new(object.enterprise_fee_adjustments).total_additional_tax
    end

    def enterprise_fee_included_tax
      EnterpriseFeeAdjustments.new(object.enterprise_fee_adjustments).total_included_tax
    end
  end
end
