class Api::Admin::StandingOrderSerializer < ActiveModel::Serializer
  attributes :id, :shop_id, :customer_id, :schedule_id, :payment_method_id, :shipping_method_id, :begins_at, :ends_at

  has_many :standing_line_items

  def begins_at
    object.begins_at.andand.strftime('%F')
  end

  def ends_at
    object.ends_at.andand.strftime('%F')
  end
end
