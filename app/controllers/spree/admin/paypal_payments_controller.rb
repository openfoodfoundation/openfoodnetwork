# frozen_string_literal: true

module Spree
  module Admin
    class PaypalPaymentsController < Spree::Admin::BaseController
      before_action :load_order

      def index
        @payments = @order.payments.includes(:payment_method).
          where(spree_payment_methods: { type: "Spree::Gateway::PayPalExpress" })
      end

      private

      def load_order
        @order = Spree::Order.where(number: params[:order_id]).first
      end
    end
  end
end
