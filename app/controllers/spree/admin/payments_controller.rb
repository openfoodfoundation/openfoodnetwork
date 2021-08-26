# frozen_string_literal: true

module Spree
  module Admin
    class PaymentsController < Spree::Admin::BaseController
      include FullUrlHelper

      before_action :load_order, except: [:show]
      before_action :load_payment, only: [:fire, :show]
      before_action :load_data
      before_action :can_transition_to_payment
      # We ensure that items are in stock before all screens if the order is in the Payment state.
      # This way, we don't allow someone to enter credit card details for an order only to be told
      # that it can't be processed.
      before_action :ensure_sufficient_stock_lines

      respond_to :html

      def index
        @payments = @order.payments
        redirect_to spree.new_admin_order_payment_url(@order) if @payments.empty?
      end

      def new
        @payment = @order.payments.build
      end

      def create
        @payment = @order.payments.build(object_params)
        load_payment_source

        begin
          unless @payment.save
            redirect_to spree.admin_order_payments_path(@order)
            return
          end

          @payment.authorize!(full_order_path(@payment.order))
          @payment.request_user_authorization do
            PaymentMailer.authorize_payment(@payment).deliver_later
          end

          if @order.completed?
            @payment.authorize!(full_order_path(@payment.order))
            @payment.request_user_authorization do
              PaymentMailer.authorize_payment(@payment).deliver_later
            end

            @payment.process_offline!
            flash[:success] = flash_message_for(@payment, :successfully_created)

            redirect_to spree.admin_order_payments_path(@order)
          else
            OrderWorkflow.new(@order).complete!

            @payment.authorize!(full_order_path(@payment.order))
            @payment.request_user_authorization do
              PaymentMailer.authorize_payment(@payment).deliver_later
            end

            @payment.process_offline!

            flash[:success] = Spree.t(:new_order_completed)
            redirect_to spree.edit_admin_order_url(@order)
          end
        rescue Spree::Core::GatewayError => e
          flash[:error] = e.message.to_s
          redirect_to spree.new_admin_order_payment_path(@order)
        rescue StateMachines::InvalidTransition
          flash[:error] = I18n.t('authorization_failure')
          redirect_to spree.new_admin_order_payment_path(@order)
        end
      end

      # When a user fires an event, take them back to where they came from
      # (we can't use respond_override because Spree no longer uses respond_with)
      def fire
        event = params[:e]
        return unless event && @payment.payment_source

        # Because we have a transition method also called void, we do this to avoid conflicts.
        event = "void_transaction" if event == "void"
        if allowed_events.include?(event) && @payment.public_send("#{event}!")
          flash[:success] = t(:payment_updated)
        else
          flash[:error] = t(:cannot_perform_operation)
        end
      rescue StandardError => e
        flash[:error] = e.message
      ensure
        redirect_to request.referer
      end

      def paypal_refund
        if request.get?
          if @payment.source.state == 'refunded'
            flash[:error] = Spree.t(:already_refunded, scope: 'paypal')
            redirect_to admin_order_payment_path(@order, @payment)
          end
        elsif request.post?
          response = @payment.payment_method.refund(@payment, params[:refund_amount])
          if response.success?
            flash[:success] = Spree.t(:refund_successful, scope: 'paypal')
            redirect_to admin_order_payments_path(@order)
          else
            flash.now[:error] = Spree.t(:refund_unsuccessful, scope: 'paypal') +
                                " (#{response.errors.first.long_message})"
            render
          end
        end
      end

      private

      def load_payment_source
        if @payment.payment_method.is_a?(Spree::Gateway) &&
           @payment.payment_method.payment_profiles_supported? &&
           params[:card].present? &&
           (params[:card] != 'new')
          @payment.source = CreditCard.find_by(id: params[:card])
        end
      end

      def object_params
        if params[:payment] &&
           params[:payment_source] &&
           source_params = params.delete(:payment_source)[params[:payment][:payment_method_id]]
          params[:payment][:source_attributes] = source_params
        end

        params.require(:payment).permit(
          :amount, :payment_method_id,
          source_attributes: ::PermittedAttributes::PaymentSource.attributes
        )
      end

      def load_data
        @amount = params[:amount] || load_order.total

        # Only show payments for the order's distributor
        @payment_methods = PaymentMethod.
          available(:back_end).
          for_distributor(@order.distributor)

        @payment_method = if @payment&.payment_method
                            @payment.payment_method
                          else
                            @payment_methods.first
                          end

        @previous_cards = @order.credit_cards.with_payment_profile
      end

      # At this point admin should have passed through Customer Details step
      # where order.next is called which leaves the order in payment step
      #
      # Orders in complete or canceled step also allows to access this controller
      #
      # Otherwise redirect user to that step
      def can_transition_to_payment
        return if @order.payment? || @order.complete? || @order.canceled? || @order.resumed?

        flash[:notice] = Spree.t(:fill_in_customer_info)
        redirect_to spree.edit_admin_order_customer_url(@order)
      end

      def ensure_sufficient_stock_lines
        return if !@order.payment? || @order.insufficient_stock_lines.blank?

        flash[:error] = I18n.t("spree.orders.line_item.insufficient_stock",
                               on_hand: "0 #{out_of_stock_item_names}")
        redirect_to spree.edit_admin_order_url(@order)
      end

      def out_of_stock_item_names
        @order.insufficient_stock_lines.map do |line_item|
          line_item.variant.name
        end.join(", ")
      end

      def load_order
        @order = Order.find_by!(number: params[:order_id])
        authorize! action, @order
        @order
      end

      def load_payment
        @payment = Payment.find(params[:id])
      end

      def allowed_events
        %w{capture void_transaction credit refund resend_authorization_email}
      end
    end
  end
end
