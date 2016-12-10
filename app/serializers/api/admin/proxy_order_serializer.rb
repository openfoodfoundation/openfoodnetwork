class Api::Admin::ProxyOrderSerializer < ActiveModel::Serializer
  attributes :id, :state, :edit_path, :number, :completed_at, :order_cycle_id, :total

  def total
    object.total.to_money.to_s
  end

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.strftime("%F %T")
  end

  def edit_path
    spree.edit_admin_order_path(object.order)
  end
end
