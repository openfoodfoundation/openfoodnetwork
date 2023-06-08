# frozen_string_literal: true

module Spree
  module Admin
    class AdjustmentsController < ::Admin::ResourceController
      belongs_to 'spree/order', find_by: :number

      before_action :set_order_id, only: [:create, :update]
      before_action :skip_changing_canceled_orders, only: [:create, :update]
      after_action :update_order, only: [:create, :update, :destroy]
      after_action :apply_tax, only: [:create, :update]

      private

      def update_order
        @order.reload
        @order.update_totals_and_states
      end

      def collection
        order_adjustments = parent.adjustments.where.not(originator_type: 'EnterpriseFee')
        admin_adjustments = parent.adjustments.admin
        payment_fees = parent.all_adjustments.payment_fee.eligible
        shipping_fees = parent.all_adjustments.shipping

        order_adjustments.or(admin_adjustments) | payment_fees.or(shipping_fees)
      end

      def find_resource
        parent.all_adjustments.eligible.find(params[:id])
      end

      def set_order_id
        @adjustment.order_id = parent.id
      end

      def skip_changing_canceled_orders
        return unless @order.canceled?

        flash[:error] = t("admin.adjustments.skipped_changing_canceled_order")
        redirect_to admin_order_adjustments_path(@order) if @order.canceled?
      end

      def apply_tax
        Spree::TaxRate.adjust(@order, [@adjustment])
      end

      def permitted_resource_params
        params.require(:adjustment).permit(
          :label, :amount, :tax_category_id
        )
      end
    end
  end
end
