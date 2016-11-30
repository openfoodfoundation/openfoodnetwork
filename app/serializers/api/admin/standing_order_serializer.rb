class Api::Admin::StandingOrderSerializer < ActiveModel::Serializer
  attributes :id, :shop_id, :customer_id, :schedule_id, :payment_method_id, :shipping_method_id, :begins_at, :ends_at
  attributes :customer_email, :schedule_name, :edit_path

  has_many :standing_line_items, serializer: Api::Admin::StandingLineItemSerializer
  has_one :bill_address, serializer: Api::AddressSerializer
  has_one :ship_address, serializer: Api::AddressSerializer

  def begins_at
    object.begins_at.andand.strftime('%F')
  end

  def ends_at
    object.ends_at.andand.strftime('%F')
  end

  def customer_email
    object.customer.andand.email
  end

  def schedule_name
    object.schedule.andand.name
  end

  def edit_path
    return '' unless object.id
    edit_admin_standing_order_path(object)
  end
end
