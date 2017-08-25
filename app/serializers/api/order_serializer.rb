module Api
  class OrderSerializer < ActiveModel::Serializer
    attributes :number, :completed_at, :total, :state, :shipment_state, :payment_state
    attributes :outstanding_balance, :payments, :path, :cancel_path
    attributes :changes_allowed, :changes_allowed_until, :item_count
    attributes :shop_id

    has_many :payments, serializer: Api::PaymentSerializer

    def payments
      object.payments.joins(:payment_method).completed
    end

    def shop_id
      object.distributor_id
    end

    def item_count
      object.line_items.sum(&:quantity)
    end

    def completed_at
      object.completed_at.blank? ? "" : I18n.l(object.completed_at, format: "%b %d, %Y %H:%M")
    end

    def changes_allowed_until
      return I18n.t(:not_allowed) unless object.changes_allowed?
      I18n.l(object.order_cycle.andand.orders_close_at, format: "%b %d, %Y %H:%M")
    end

    def total
      object.total.to_money.to_s
    end

    def shipment_state
      object.shipment_state ? object.shipment_state : nil
    end

    def payment_state
      object.payment_state ? object.payment_state : nil
    end

    def state
      object.state ? object.state : nil
    end

    def path
      Spree::Core::Engine.routes_url_helpers.order_path(object)
    end

    def cancel_path
      return nil unless object.changes_allowed?
      Spree::Core::Engine.routes_url_helpers.cancel_order_path(object)
    end

    def changes_allowed
      object.changes_allowed?
    end
  end
end
