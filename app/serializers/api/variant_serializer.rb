class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display, 
    :on_demand, :price, :fees, :base_price

  def price
    object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
  end

  def base_price
    object.price
  end

  def fees
    object.fees_by_type_for(options[:current_distributor], options[:current_order_cycle])
  end
end
