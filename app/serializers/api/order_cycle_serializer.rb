# frozen_string_literal: true

module Api
  class OrderCycleSerializer < ActiveModel::Serializer
    attributes :order_cycle_id, :orders_close_at

    def order_cycle_id
      object.id
    end

    def orders_close_at
      object.orders_close_at.to_s
    end
  end
end
