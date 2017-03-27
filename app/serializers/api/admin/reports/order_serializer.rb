class Api::Admin::Reports::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :display_total, :customer, :email

  def customer
    object.bill_address.full_name
  end

  def display_total
    object.display_total.to_s
  end

  # has_one :shop, serializer: Api::Admin::IdSerializer
  # has_one :address, serializer: Api::Admin::IdSerializer
end
