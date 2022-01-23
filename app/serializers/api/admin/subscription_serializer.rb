# frozen_string_literal: true

module Api
  module Admin
    class SubscriptionSerializer < ActiveModel::Serializer
      attributes :id, :shop_id, :customer_id, :schedule_id, :payment_method_id, :shipping_method_id,
                 :begins_at, :ends_at, :customer_email, :customer_first_name, :customer_last_name,
                 :customer_full_name, :schedule_name, :edit_path, :canceled_at, :paused_at, :state,
                 :shipping_fee_estimate, :payment_fee_estimate

      has_many :subscription_line_items, serializer: Api::Admin::SubscriptionLineItemSerializer
      has_many :closed_proxy_orders, serializer: Api::Admin::ProxyOrderSerializer
      has_many :not_closed_proxy_orders, serializer: Api::Admin::ProxyOrderSerializer
      has_one :bill_address, serializer: Api::AddressSerializer
      has_one :ship_address, serializer: Api::AddressSerializer

      def begins_at
        object.begins_at&.strftime('%F')
      end

      def ends_at
        object.ends_at&.strftime('%F')
      end

      def paused_at
        object.paused_at&.strftime('%F')
      end

      def canceled_at
        object.canceled_at&.strftime('%F')
      end

      def customer_email
        object.customer&.email
      end

      def customer_first_name
        object.customer&.first_name
      end

      def customer_last_name
        object.customer&.last_name
      end

      def customer_full_name
        object.customer&.full_name
      end

      def schedule_name
        object.schedule&.name
      end

      def edit_path
        return '' unless object.id

        edit_admin_subscription_path(object)
      end

      def shipping_fee_estimate
        object.shipping_fee_estimate.to_f
      end

      def payment_fee_estimate
        object.payment_fee_estimate.to_f
      end
    end
  end
end
