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
      before_action :authorize_order, only: [:capture, :ship]

      def index
        orders = SearchOrders.new(search_params, spree_current_user).orders
        @pagy, @orders = pagy(orders, items: params[:per_page] || 15)
        @stored_query = search_params.to_query
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

        ::Orders::WorkflowService.new(@order).advance_to_payment

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

        redirect_back(fallback_location: spree.admin_dashboard_path)
      end

      def invoice
        Spree::OrderMailer.invoice_email(@order.id,
                                         current_user_id: spree_current_user.id ).deliver_later
        flash[:success] = t('admin.orders.invoice_email_sent')

        redirect_to spree.edit_admin_order_path(@order)
      end

      def print
        if OpenFoodNetwork::FeatureToggle.enabled?(:invoices, spree_current_user)
          @order = if params[:invoice_id].present?
                     @order.invoices.find(params[:invoice_id]).presenter
                   else
                     ::Orders::GenerateInvoiceService.new(@order).generate_or_update_latest_invoice
                     @order.invoices.first.presenter
                   end
        end

        render_with_wicked_pdf InvoiceRenderer.new.args(@order, spree_current_user)
      end

      def capture
        payment_capture = ::Orders::CaptureService.new(@order)
        unless (@saved = payment_capture.call)
          message = payment_capture.gateway_error || I18n.t(:payment_processing_failed)
        end

        respond_to do |format|
          format.html do
            flash[:error] = message unless @saved
            redirect_to admin_orders_path
          end
          format.turbo_stream do
            flash.now[:error] = message unless @saved
            render 'spree/admin/orders/capture'
          end
        end
      end

      def ship
        @order.send_shipment_email = false unless params[:send_shipment_email]
        @order.send_shipment_email
        if @order.ship
          return redirect_back fallback_location: admin_orders_path if params[:current_page] != 'index'

          @shipped = true
        end

        respond_to do |format|
          format.html do
            flash[:error] = I18n.t("api.orders.failed_to_update") unless @shipped
            redirect_back fallback_location: admin_orders_path
          end
          format.turbo_stream do
            flash.now[:error] = I18n.t("api.orders.failed_to_update") unless @shipped
            render 'spree/admin/orders/ship'
          end
        end
      end

      def bulk_invoice
        visible_orders = bulk_load_orders

        return if notify_if_abn_related_issue(visible_orders)

        @file_id = "#{Time.zone.now.to_i}-#{SecureRandom.hex(2)}"

        # Preserve order of bulk_ids.
        # The ids are supplied in the sequence of the orders screen and may be
        # sorted, for example by last name of the customer.
        visible_order_ids = params[:bulk_ids].map(&:to_i) & visible_orders.pluck(:id)

        BulkInvoiceJob.perform_later(
          visible_order_ids,
          "tmp/invoices/#{@file_id}.pdf",
          channel: SessionChannel.for_request(request),
          current_user_id: spree_current_user.id
        )
        respond_to do |format|
          format.html { redirect_to admin_orders_path }
          format.turbo_stream { render 'spree/admin/orders/bulk_invoice' }
        end
      end

      def cancel_orders
        @cancelled_orders = ::Orders::BulkCancelService.new(params, spree_current_user).call

        respond_to do |format|
          format.html { redirect_to admin_orders_path }
          format.turbo_stream { render 'spree/admin/orders/cancel_orders' }
        end
      end

      def resend_confirmation_emails
        editable_orders.where(id: params[:bulk_ids]).find_each do |order|
          next unless can? :resend, order

          Spree::OrderMailer.confirm_email_for_customer(order.id, true).deliver_later
        end

        message = t("admin.resend_confirmation_emails_feedback", count: params[:bulk_ids].count)

        respond_to do |format|
          format.html do
            flash[:success] = message
            redirect_to admin_orders_path
          end
          format.turbo_stream do
            flash.now[:success] = message
            render 'spree/admin/orders/resend_confirmation_emails'
          end
        end
      end

      def send_invoices
        count = 0
        editable_orders.invoiceable.where(id: params[:bulk_ids]).find_each do |o|
          next unless o.distributor.can_invoice?

          Spree::OrderMailer.invoice_email(o.id,
                                           current_user_id: current_spree_user.id).deliver_later
          count += 1
        end

        respond_to do |format|
          format.html do
            flash[:success] = t("admin.send_invoice_feedback", count:)
            redirect_to admin_orders_path
          end
          format.turbo_stream do
            flash.now[:success] = t("admin.send_invoice_feedback", count:)
            render 'spree/admin/orders/send_invoices'
          end
        end
      end

      private

      def line_items_present?
        return true if @order.line_items.any?

        @order.errors.add(:line_items, Spree.t('errors.messages.blank'))
        false
      end

      def search_params
        default_filters.deep_merge(
          params.permit(:page, :per_page, :shipping_method_id, q: {})
        ).to_h.with_indifferent_access
      end

      def default_filters
        { q: { completed_at_not_null: 1, s: "completed_at desc" } }
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

      def authorize_order
        @order = Spree::Order.find_by(number: params[:id])
        authorize! :admin, @order
      end

      def set_param_for_controller
        redirect_back fallback_location: admin_orders_path
        params[:id] = @order.number
      end

      def bulk_load_orders
        editable_orders.invoiceable.where(id: params[:bulk_ids])
      end

      def notify_if_abn_related_issue(orders)
        return false unless abn_required?

        distributors = distributors_without_abn(orders)
        return false if distributors.empty?

        render_business_number_required_error(distributors)
        true
      end

      def abn_required?
        Spree::Config.enterprise_number_required_on_invoices?
      end

      def distributors_without_abn(orders)
        abn = if OpenFoodNetwork::FeatureToggle.enabled?(:invoices)
                [nil, ""]
              else
                [nil]
              end
        Enterprise.where(
          id: orders.select(:distributor_id),
          abn:,
        )
      end

      def render_business_number_required_error(distributors)
        distributor_names = distributors.pluck(:name)

        respond_to do |format|
          format.html do
            flash[:error] = I18n.t(:must_have_valid_business_number,
                                   enterprise_name: distributor_names.join(", "))
            redirect_to admin_orders_path
          end
          format.turbo_stream do
            flash[:error] = I18n.t(:must_have_valid_business_number,
                                   enterprise_name: distributor_names.join(", "))
            render turbo_stream:
              turbo_stream.append(
                "flashes",
                partial: 'admin/shared/flashes', locals: { flashes: flash }
              )
          end
        end
      end

      def editable_orders
        Permissions::Order.new(current_spree_user).editable_orders
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
