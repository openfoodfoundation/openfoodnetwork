# frozen_string_literal: true

module Spree
  module Admin
    class PaymentsController < Spree::Admin::BaseController
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
        # Try to redeem VINE voucher first as we don't want to create a payment and complete
        # the order if it fails
        return redirect_to spree.admin_order_payments_path(@order) unless redeem_vine_voucher

        @payment = @order.payments.build(object_params)
        load_payment_source
        begin
          unless @payment.save
            redirect_to spree.admin_order_payments_path(@order)
            return
          end

          ::Orders::WorkflowService.new(@order).complete! unless @order.completed?

          authorize_stripe_sca_payment
          @payment.process_offline!
          flash[:success] = flash_message_for(@payment, :successfully_created)
          redirect_to spree.admin_order_payments_path(@order)
        rescue Spree::Core::GatewayError => e
          flash[:error] = e.message.to_s
          redirect_to spree.admin_order_payments_path(@order)
        end
      end

      # When a user fires an event, take them back to where they came from
      # (we can't use respond_override because Spree no longer uses respond_with)
      def fire
        event = params[:e]
        return unless event

        # capture_and_complete_order will complete the order, so we want to try to redeem VINE
        # voucher first and exit if it fails
        return if event == "capture_and_complete_order" && !redeem_vine_voucher

        # Because we have a transition method also called void, we do this to avoid conflicts.
        event = "void_transaction" if event == "void"
        if allowed_events.include?(event) && @payment.public_send("#{event}!")
          flash[:success] = t(:payment_updated)
        else
          flash[:error] = t(:cannot_perform_operation)
        end
      rescue StandardError => e
        logger.error e.message
        Alert.raise(e)
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
        if @payment.payment_method.is_a?(Gateway::StripeSCA) &&
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

        credit_card_ids = @order.payments.from_credit_card.pluck(:source_id).uniq
        @previous_cards = CreditCard.where(id: credit_card_ids).with_payment_profile
      end

      # At this point admin should have passed through Customer Details step
      # where order.next is called which leaves the order in payment step
      #
      # Orders in complete or canceled step also allows to access this controller
      #
      # Otherwise redirect user to that step
      def can_transition_to_payment
        return if @order.confirmation? || @order.payment? ||
                  @order.complete? || @order.canceled? || @order.resumed?

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

      def authorize_stripe_sca_payment
        return unless @payment.payment_method.instance_of?(Spree::Gateway::StripeSCA)

        OrderManagement::Order::StripeScaPaymentAuthorize.
          new(@order, payment: @payment, off_session: true).call!

        raise Spree::Core::GatewayError, I18n.t('authorization_failure') if @order.errors.any?

        return unless @payment.requires_authorization?

        raise Spree::Core::GatewayError, I18n.t('action_required')
      end

      def allowed_events
        %w{capture void_transaction credit refund resend_authorization_email
           capture_and_complete_order}
      end

      def redeem_vine_voucher
        vine_voucher_redeemer = Vine::VoucherRedeemerService.new(order: @order)
        if vine_voucher_redeemer.redeem == false
          # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
          flash[:error] = if vine_voucher_redeemer.errors.keys.include?(:redeeming_failed)
                            vine_voucher_redeemer.errors[:redeeming_failed]
                          else
                            I18n.t('checkout.errors.voucher_redeeming_error')
                          end
          # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
          return false
        end

        true
      end
    end
  end
end
