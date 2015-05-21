class Api::Admin::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :full_name, :email, :phone, :completed_at, :line_items

  has_one :distributor, serializer: Api::Admin::IdNameSerializer
  has_one :order_cycle, serializer: Api::Admin::BasicOrderCycleSerializer

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

  def line_items
    # we used to have a scope here, but we are at the point where a user which can edit an order
    # should be able to edit all of the line_items as well, making the scope redundant
    ActiveModel::ArraySerializer.new(
      object.line_items.order('id ASC'),
      {each_serializer: Api::Admin::LineItemSerializer}
    )
  end
end
