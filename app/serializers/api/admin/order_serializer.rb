class Api::Admin::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :full_name, :email, :phone, :completed_at

  has_one :distributor, serializer: Api::Admin::IdSerializer
  has_one :order_cycle, serializer: Api::Admin::IdSerializer

  def full_name
    object.billing_address.nil? ? "" : ( object.billing_address.full_name || "" )
  end

  def email
    object.email || ""
  end

  def phone
    object.billing_address.nil? ? "a" : ( object.billing_address.phone || "" )
  end

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.strftime("%F %T")
  end
end
