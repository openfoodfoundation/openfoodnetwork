class Api::Admin::StandingLineItemSerializer < ActiveModel::Serializer
  attributes :id, :variant_id, :quantity, :description, :price_estimate

  def description
    "#{object.variant.product.name} - #{object.variant.full_name}"
  end

  def price_estimate
    if object.price_estimate
      object.price_estimate
    elsif options[:fee_calculator]
      (object.variant.price + options[:fee_calculator].indexed_fees_for(object.variant)).to_f
    else
      "?"
    end
  end
end
