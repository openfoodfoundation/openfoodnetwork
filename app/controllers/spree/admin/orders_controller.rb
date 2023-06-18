# frozen_string_literal: true

require 'open_food_network/spree_api_key_loader'

module Spree
  module Admin
    class OrdersController < Spree::Admin::BaseController
      include OpenFoodNetwork::SpreeApiKeyLoader
      helper CheckoutHelper

      before_action :load_order, only: [:edit, :update, :fire, :resend, :invoice, :print]
      before_action :load_distribution_choices, only: [:new, :create, :edit, :update]
      before_action :require_distributor_abn, only: :invoice
      before_action :restore_saved_query!, only: :index

      respond_to :html, :json

      def index
        orders = SearchOrders.new(search_params, spree_current_user).orders
        @pagy, @orders = pagy(orders, items: params[:per_page] || 15)

        update_search_results if searching?
      end

      def new
        @order = Spree::Order.new
      end

      def edit
        @order.shipments.map(&:refresh_rates)
      end

      def create
        @order = Spree::Order.new(order_params.merge(created_by: spree_current_user))

        if @order.save(context: :require_distribution)
          redirect_to spree.admin_order_customer_path(@order)
        else
          render :new
        end
      end

      def update
        on_update

        order_updated = order_params.present? && @order.update(order_params)

        unless order_updated && line_items_present?
          flash[:error] = @order.errors.full_messages.join(', ') if @order.errors.present?
          return redirect_to spree.edit_admin_order_path(@order)
        end

        OrderWorkflow.new(@order).advance_to_payment

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
        if OpenFoodNetwork::FeatureToggle.enabled?(:invoices)
          @order = @order.invoices.find(params[:invoice_id]).presenter
        end

        render_with_wicked_pdf InvoiceRenderer.new.args(@order)
      end

      private

      def line_items_present?
        return true if @order.line_items.any?

        @order.errors.add(:line_items, Spree.t('errors.messages.blank'))
        false
      end

      def update_search_results
        session[:admin_orders_search] = search_params

        render cable_ready: cable_car.inner_html(
          "#orders-index",
          partial("spree/admin/orders/table", locals: { pagy: @pagy, orders: @orders })
        )
      end

      def searching?
        params[:q].present? && request.format.symbol == :cable_ready
      end

      def search_params
        default_filters.deep_merge(
          params.permit(:page, :per_page, :shipping_method_id, q: {})
        ).to_h.with_indifferent_access
      end

      def default_filters
        { q: { completed_at_not_null: 1, s: "completed_at desc" } }
      end

      def restore_saved_query!
        return unless request.format.html?

        @_params = ActionController::Parameters.new(session[:admin_orders_search] || {})
        @stored_query = search_params.to_query
      end

      def on_update
        @order.recreate_all_fees!

        return if @order.cart?

        @order.create_tax_charge!
        @order.update_order!
      end

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
    end
  end
end
