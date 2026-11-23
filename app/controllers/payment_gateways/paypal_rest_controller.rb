# frozen_string_literal: true

module PaymentGateways
  class PaypalRestController < BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :load_checkout_order, only: [:create, :confirm]
    before_action :handle_insufficient_stock, only: [:create, :confirm]
    before_action -> { check_order_cycle_expiry(should_empty_order: false) }, only: [
      :create, :confirm
    ]
    before_action :permit_parameters!, only: [:create, :confirm]

    def create
      return redirect_to order_failed_route if @any_out_of_stock == true
      return fail_checkout("No pending PayPal payment found") if pending_payment.nil?

      result = payment_method.provider.create_order(order_request, request_id: create_request_id)

      if result.success? && result.approval_url.present?
        redirect_to result.approval_url, allow_other_host: true
      else
        fail_checkout(
          result.error_message.presence || "PayPal did not return an approval URL", alert: true
        )
      end
    end

    def confirm
      return redirect_to order_failed_route if @any_out_of_stock == true

      payment = pending_payment

      if payment.nil? || params[:token].blank?
        flash[:error] = Spree.t('flash.no_payment_found', scope: 'paypal')
        return redirect_to main_app.checkout_step_path(:payment)
      end

      # The PayPal order ID is returned as `token`. The capture happens later,
      # when Spree processes the payment and calls the gateway's #purchase.
      payment.update!(source: paypal_source)

      process_payment_completion!
    end

    def cancel
      flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
      redirect_to main_app.checkout_path
    end

    private

    def permit_parameters!
      params.permit(:token, :payment_method_id, :PayerID)
    end

    def order_request
      PaypalRest::OrderRequestBuilderService.new(
        order: @order,
        payment: pending_payment,
        payment_method: payment_method,
        return_url: return_url,
        cancel_url: cancel_url
      ).call
    end

    def return_url
      payment_gateways_confirm_paypal_rest_url(payment_method_id: payment_method.id)
    end

    def cancel_url
      payment_gateways_cancel_paypal_rest_url
    end

    def payment_method
      @payment_method ||= pending_payment&.payment_method ||
                          Spree::PaymentMethod.find(params.expect(:payment_method_id))
    end

    def create_request_id
      "ofn-create-#{@order.number}-#{pending_payment.id}"
    end

    def pending_payment
      @pending_payment ||= begin
        payments = @order.pending_payments.select do |payment|
          payment.payment_method.is_a?(Spree::Gateway::PayPalRest) &&
            (params[:payment_method_id].blank? ||
              payment.payment_method_id == params[:payment_method_id].to_i)
        end

        payments.max_by(&:created_at)
      end
    end

    def paypal_source
      source = Spree::PaypalRestCheckout.find_or_initialize_by(order_id: params[:token])
      source.payer_id = params[:PayerID] if params[:PayerID].present?
      source.save!
      source
    rescue ActiveRecord::RecordNotUnique
      # A duplicate callback can win the race on the unique order_id index.
      source = Spree::PaypalRestCheckout.find_by!(order_id: params.expect(:token))
      source.update!(payer_id: params[:PayerID]) if params[:PayerID].present?
      source
    end

    def fail_checkout(message, alert: false)
      if alert
        Rails.logger.error("PaypalRestController#create: #{message}")
        Alert.raise_with_record(StandardError.new(message), @order)
      else
        Rails.logger.info("PaypalRestController#create: #{message}")
      end

      flash[:error] = Spree.t(
        'flash.generic_error',
        scope: 'paypal',
        reasons: message,
      )

      redirect_to main_app.checkout_step_path(:payment)
    end
  end
end
