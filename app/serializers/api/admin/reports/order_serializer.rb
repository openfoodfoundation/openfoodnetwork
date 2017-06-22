class Api::Admin::Reports::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :display_total, :total, :customer, :customer_id, :email, :created_at, :completed_at, :payment_method,
    :special_instructions, :outstanding_balance, :payment_total, :shipping_method, :require_ship_address, :order_cycle_name,
    :customer_code, :customer_tags, :admin_and_handling_total, :ship_total, :payment_fee, :total

  has_one :distributor, serializer: Api::Admin::IdNameSerializer
  has_one :ship_address, serializer: Api::Admin::Reports::AddressSerializer
  has_one :bill_address, serializer: Api::Admin::Reports::AddressSerializer

  def created_at
    object.created_at.to_s
  end

  def completed_at
    object.completed_at.to_s
  end

  def customer_id
    object.bill_address.id
  end

  def customer
    object.bill_address.full_name
  end

  def display_total
    object.display_total.to_s
  end

  def payment_method
    object.payments.first.andand.payment_method.andand.name
  end

  def shipping_method
    object.shipping_method.andand.name
  end

  def require_ship_address
    require_ship_address? ? 'Y' : 'N'
  end

  def include_ship_address?
    require_ship_address?
  end

  def order_cycle_name
    object.order_cycle.name
  end

  def customer_code
    object.user.andand.customer_of(object.distributor).andand.code
  end

  def customer_tags
    object.user.andand.customer_of(object.distributor).andand.tags.andand.join(', ')
  end

  private
  def require_ship_address?
    @require_ship_address ||= object.shipping_method.andand.require_ship_address
  end

end
