class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display
  attributes :options_text, :on_demand, :price, :fees, :price_with_fees, :product_name
  attributes :tag_list

  def price
    object.price
  end

  def fees
    options[:enterprise_fee_calculator].andand.indexed_fees_by_type_for(object) ||
      object.fees_by_type_for(options[:current_distributor], options[:current_order_cycle])
  end

  def price_with_fees
    if options[:enterprise_fee_calculator]
      object.price + options[:enterprise_fee_calculator].indexed_fees_for(object)
    else
      object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
    end
  end

  def product_name
    object.product.name
  end
end
