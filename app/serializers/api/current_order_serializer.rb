class Api::CurrentOrderSerializer < ActiveModel::Serializer
  attributes :id, :item_total, :email, :shipping_method_id,
             :display_total, :payment_method_id

  has_one :bill_address, serializer: Api::AddressSerializer
  has_one :ship_address, serializer: Api::AddressSerializer

  has_many :line_items, serializer: Api::LineItemSerializer
  has_many :finalised_line_items, serializer: Api::LineItemSerializer

  def payment_method_id
    object.payments.first.andand.payment_method_id
  end

  def display_total
    object.display_total.money.to_f
  end
end
