class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display, 
    :on_demand, :price, :fees, :price_with_fees

  def price_with_fees
    object.price_with_fees(options[:current_distributor], options[:current_order_cycle]).to_f
  end

  def price
    object.price.to_f
  end

  def fees
    object.fees_by_type_for(options[:current_distributor], options[:current_order_cycle])
  end
end
