class Api::Admin::EstimatedVariantSerializer < ActiveModel::Serializer
  attributes :id, :product_name, :full_name, :price_with_fees

  def product_name
    object.product.name
  end

  def price_with_fees
    (object.price + options[:fee_calculator].indexed_fees_for(object)).to_f
  end
end
