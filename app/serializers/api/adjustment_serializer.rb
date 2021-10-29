# frozen_string_literal: true

module Api
  class AdjustmentSerializer < ActiveModel::Serializer
    attributes :id, :amount, :label, :eligible,
               :adjustable_type, :adjustable_id,
               :originator_type, :originator_id,
               :tax_category_id

    def tax_category_id
      if object.originator_type == "Spree::TaxRate"
        object.originator.tax_category_id
      else
        object.tax_category_id
      end
    end
  end
end
