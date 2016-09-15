class Api::Admin::EstimatedVariantSerializer < ActiveModel::Serializer
  attributes :variant_id, :description, :price_with_fees

  def variant_id
    object.id
  end

  def description
    "#{object.product.name} - #{object.full_name}"
  end

  def price_with_fees
    (object.price + options[:fee_calculator].indexed_fees_for(object)).to_f
  end
end
