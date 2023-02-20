# frozen_string_literal: true

require 'open_food_network/spree_api_key_loader'

module Spree
  module Admin
    class OrdersController < Spree::Admin::BaseController
      include OpenFoodNetwork::SpreeApiKeyLoader
      helper CheckoutHelper

      before_action :load_order, only: [:edit, :update, :fire, :resend,
                                        :invoice, :print]
      before_action :load_distribution_choices, only: [:new, :edit, :update]

      # Ensure that the distributor is set for an order when
      before_action :ensure_distribution, only: :new
      before_action :require_distributor_abn, only: :invoice

      respond_to :html, :json

      def new
        @order = Order.create
        @order.created_by = spree_current_user
        @order.save
        redirect_to spree.edit_admin_order_url(@order)
      end

      def edit
        @order.shipments.map(&:refresh_rates)

        OrderWorkflow.new(@order).advance_to_payment
        @order.errors.clear
      end

      def update
        @order.recreate_all_fees!

        unless @order.cart?
          @order.create_tax_charge!
          @order.update_order!
        end

        if params[:set_distribution_step] && @order.update(order_params)
          return redirect_to spree.admin_order_customer_path(@order)
        end

        unless order_params.present? && @order.update(order_params) && @order.line_items.present?
          if @order.line_items.empty? && !params[:suppress_error_msg]
            @order.errors.add(:line_items, Spree.t('errors.messages.blank'))
          end

          flash[:error] = @order.errors.full_messages.join(', ') if @order.errors.present?
          return redirect_to spree.edit_admin_order_path(@order)
        end

        if @order.complete?
          redirect_to spree.edit_admin_order_path(@order)
        else
          # Jump to next step if order is not complete
          redirect_to spree.admin_order_payments_path(@order)
        end
      end

      def bulk_management
        load_spree_api_key
      end

      def fire
        event = params[:e]
        @order.send_cancellation_email = params[:send_cancellation_email] != "false"
        @order.restock_items = params.fetch(:restock_items, "true") == "true"

        if @order.public_send(event.to_s)
          flash[:success] = Spree.t(:order_updated)
        else
          flash[:error] = Spree.t(:cannot_perform_operation)
        end
      rescue Spree::Core::GatewayError => e
        flash[:error] = e.message.to_s
      ensure
        redirect_back fallback_location: spree.admin_dashboard_path
      end

      def resend
        Spree::OrderMailer.confirm_email_for_customer(@order.id, true).deliver_later
        flash[:success] = t('admin.orders.order_email_resent')

        respond_with(@order) do |format|
          format.html { redirect_back(fallback_location: spree.admin_dashboard_path) }
        end
      end

      def invoice
        Spree::OrderMailer.invoice_email(@order.id).deliver_later
        flash[:success] = t('admin.orders.invoice_email_sent')

        respond_with(@order) { |format|
          format.html { redirect_to spree.edit_admin_order_path(@order) }
        }
      end

      def print
        render_with_wicked_pdf InvoiceRenderer.new.args(@order)
      end

      private

      def order_params
        return params[:order] if params[:order].blank?

        params.require(:order).permit(:distributor_id, :order_cycle_id)
      end

      def load_order
        if params[:id]
          @order = Order.includes(:adjustments, :shipments, line_items: :adjustments).
            find_by!(number: params[:id])
        end
        authorize! action, @order
      end

      def model_class
        Spree::Order
      end

      def require_distributor_abn
        return if @order.distributor.can_invoice?

        flash[:error] = t(:must_have_valid_business_number,
                          enterprise_name: @order.distributor.name)
        respond_with(@order) { |format|
          format.html { redirect_to spree.edit_admin_order_path(@order) }
        }
      end

      def load_distribution_choices
        @shops = Enterprise.is_distributor.managed_by(spree_current_user).by_name

        ocs = OrderCycle.includes(:suppliers, :distributors).managed_by(spree_current_user)
        @order_cycles = ocs.soonest_closing +
                        ocs.soonest_opening +
                        ocs.closed +
                        ocs.undated
      end

      def ensure_distribution
        unless @order
          @order = Spree::Order.new
          @order.generate_order_number
          @order.save!
        end
        return if @order.distribution_set?

        render 'set_distribution', locals: { order: @order }
      end
    end
  end
end
