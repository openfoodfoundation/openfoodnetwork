module Api
  class OrderSerializer < ActiveModel::Serializer
    attributes :number, :completed_at, :total, :state, :shipment_state, :payment_state, :outstanding_balance, :payments, :path

    has_many :payments, serializer: Api::PaymentSerializer

    def completed_at
      object.completed_at.blank? ? "" : I18n.l(object.completed_at, format: :long)
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
      Spree::Core::Engine.routes_url_helpers.order_url(object.number, only_path: true)
    end
  end
end
