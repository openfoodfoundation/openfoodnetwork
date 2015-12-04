class Api::Admin::BasicOrderCycleSerializer < ActiveModel::Serializer
  attributes :id, :name, :first_order, :last_order

  has_many :suppliers, serializer: Api::Admin::IdNameSerializer
  has_many :distributors, serializer: Api::Admin::IdNameSerializer

  def first_order
    object.orders_open_at.andand.strftime("%F")
  end

  def last_order
    if object.orders_close_at.present?
      (object.orders_close_at + 1.day).strftime("%F")
    else
      nil
    end
  end
end
