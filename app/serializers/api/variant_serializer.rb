class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display,
    :options_text, :on_demand, :price, :fees, :price_with_fees, :product_name

  def price
    object.price
  end

  def fees
    options[:enterprise_fee_calculator].indexed_fees_by_type_for(object)
  end

  def price_with_fees
    object.price + options[:enterprise_fee_calculator].indexed_fees_for(object)
  end

  def product_name
    object.product.name
  end
end
