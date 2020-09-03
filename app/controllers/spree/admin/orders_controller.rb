require 'open_food_network/spree_api_key_loader'

module Spree
  module Admin
    class OrdersController < Spree::Admin::BaseController
      require 'spree/core/gateway_error'
      include OpenFoodNetwork::SpreeApiKeyLoader
      helper CheckoutHelper

      before_action :load_order, only: [:edit, :update, :fire, :resend,
                                        :invoice, :print, :print_ticket]
      before_action :load_distribution_choices, only: [:new, :edit, :update]

      # Ensure that the distributor is set for an order when
      before_action :ensure_distribution, only: :new

      # After updating an order, the fees should be updated as well
      # Currently, adding or deleting line items does not trigger updating the
      # fees! This is a quick fix for that.
      # TODO: update fees when adding/removing line items
      # instead of the update_distribution_charge method.
      after_action :update_distribution_charge, only: :update

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

        OrderWorkflow.new(@order).complete

        # The payment step shows an error of 'No pending payments'
        # Clearing the errors from the order object will stop this error
        # appearing on the edit page where we don't want it to.
        @order.errors.clear
      end

      def update
        unless @order.update(order_params) && @order.line_items.present?
          if @order.line_items.empty?
            @order.errors.add(:line_items, Spree.t('errors.messages.blank'))
          end
          return redirect_to(spree.edit_admin_order_path(@order),
                             flash: { error: @order.errors.full_messages.join(', ') })
        end

        @order.update!
        if @order.complete?
          redirect_to spree.edit_admin_order_path(@order)
        else
          # Jump to next step if order is not complete
          redirect_to spree.admin_order_customer_path(@order)
        end
      end

      def bulk_management
        load_spree_api_key
      end

      def fire
        event = params[:e]
        if @order.public_send(event.to_s)
          flash[:success] = Spree.t(:order_updated)
        else
          flash[:error] = Spree.t(:cannot_perform_operation)
        end
      rescue Spree::Core::GatewayError => e
        flash[:error] = e.message.to_s
      ensure
        redirect_to :back
      end

      def resend
        Spree::OrderMailer.confirm_email_for_customer(@order.id, true).deliver
        flash[:success] = t('admin.orders.order_email_resent')

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      def invoice
        pdf = InvoiceRenderer.new.render_to_string(@order)

        Spree::OrderMailer.invoice_email(@order.id, pdf).deliver
        flash[:success] = t('admin.orders.invoice_email_sent')

        respond_with(@order) { |format| format.html { redirect_to spree.edit_admin_order_path(@order) } }
      end

      def print
        render InvoiceRenderer.new.args(@order)
      end

      def print_ticket
        render template: "spree/admin/orders/ticket", layout: false
      end

      def update_distribution_charge
        @order.update_distribution_charge!
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
        return if @order.distributor.abn.present?

        flash[:error] = t(:must_have_valid_business_number,
                          enterprise_name: @order.distributor.name)
        respond_with(@order) { |format| format.html { redirect_to spree.edit_admin_order_path(@order) } }
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
