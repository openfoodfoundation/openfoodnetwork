class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :unit_to_display, 
    :on_demand, :price, :fees, :base_price

  def price
    object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
  end

  def base_price
    1.00
  end

  def fees
    {admin: 1.23, sales: 4.56, packing: 7.89, transport: 0.12}
  end
end


# price_without_fees / price
