class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :count_on_hand, :name_to_display, :on_demand,
    :price

  has_many :images, serializer: Api::ImageSerializer

  def price
    object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
  end
end
