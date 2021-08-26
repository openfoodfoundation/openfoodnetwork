# frozen_string_literal: true

module Api
  class OrderSerializer < ActiveModel::Serializer
    attributes :number, :completed_at, :total, :state, :shipment_state, :payment_state,
               :outstanding_balance, :payments, :path, :cancel_path,
               :changes_allowed, :changes_allowed_until, :item_count,
               :shop_id

    has_many :payments, serializer: Api::PaymentSerializer

    # This method relies on `balance_value` as a computed DB column. See `CompleteOrdersWithBalance`
    # for reference.
    def outstanding_balance
      -object.balance_value
    end

    def payments
      object.payments.joins(:payment_method).where('state IN (?)', %w(completed pending))
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

      I18n.l(object.order_cycle&.orders_close_at, format: "%b %d, %Y %H:%M")
    end

    def shipment_state
      object.shipment_state || nil
    end

    def payment_state
      object.payment_state || nil
    end

    def state
      object.state || nil
    end

    def path
      order_path(object)
    end

    def cancel_path
      return nil unless object.changes_allowed?

      cancel_order_path(object)
    end

    def changes_allowed
      object.changes_allowed?
    end
  end
end
