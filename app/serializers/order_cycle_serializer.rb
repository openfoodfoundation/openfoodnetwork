class OrderCycleSerializer < ActiveModel::Serializer
  attributes :orders_close_at, id: :order_cycle_id
end
