class Api::Admin::BasicOrderCycleSerializer < ActiveModel::Serializer
  include OrderCyclesHelper

  attributes :id, :name, :status, :orders_open_at, :orders_close_at

  has_many :suppliers, serializer: Api::Admin::IdNameSerializer
  has_many :distributors, serializer: Api::Admin::IdNameSerializer

  def status
    order_cycle_status_class object
  end

  def orders_open_at
    object.orders_open_at.andand.strftime("%F")
  end

  def orders_close_at
    object.orders_close_at.andand.strftime("%F")
  end
end
