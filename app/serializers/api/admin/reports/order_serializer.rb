class Api::Admin::Reports::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :display_total, :total, :customer, :email, :created_at, :completed_at, :phone, :city, :payment_method, :special_instructions, :outstanding_balance, :payment_total

  has_one :distributor, serializer: Api::Admin::IdSerializer

  def created_at
    object.created_at.to_s
  end

  def completed_at
    object.completed_at.to_s
  end

  def customer
    object.bill_address.full_name
  end

  def display_total
    object.display_total.to_s
  end

  def phone
    object.bill_address.phone
  end

  def city
    object.bill_address.city
  end

  def payment_method
    object.payments.first.andand.payment_method.andand.name
  end
  # has_one :shop, serializer: Api::Admin::IdSerializer
  # has_one :address, serializer: Api::Admin::IdSerializer
end
