# frozen_string_literal: true

module PaymentGateways
  class PaypalController < ::BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :load_checkout_order, only: [:express, :confirm]
    before_action :handle_insufficient_stock, only: [:express, :confirm]
    before_action -> { check_order_cycle_expiry(should_empty_order: false) }, only: [
      :express, :confirm
    ]
    before_action :permit_parameters!

    after_action :reset_order_when_complete, only: :confirm

    def express
      return redirect_to order_failed_route if @any_out_of_stock == true

      pp_request = provider.build_set_express_checkout(express_checkout_request_details(@order))

      begin
        pp_response = provider.set_express_checkout(pp_request)
        if pp_response.success?
          # At this point Paypal has *provisionally* accepted that the payment can now be placed,
          # and the user will be redirected to a Paypal payment page. On completion, the user is
          # sent back and the response is handled in the #confirm action in this controller.
          redirect_to(
            provider.express_checkout_url(pp_response, useraction: 'commit'), allow_other_host: true
          )
        else
          Rails.logger.error(
            "PaypalController#express: #{pp_response.errors.map(&:long_message).join(' ')}"
          )
          Alert.raise_with_record(pp_response.errors, @order)
          flash[:error] =
            Spree.t(
              'flash.generic_error',
              scope: 'paypal',
              reasons: pp_response.errors.map(&:long_message).join(" "),
            )
          redirect_to main_app.checkout_step_path(:payment)
        end
      rescue SocketError
        flash[:error] = Spree.t('flash.connection_failed', scope: 'paypal')
        redirect_to main_app.checkout_step_path(:payment)
      end
    end

    def confirm
      return redirect_to order_failed_route if @any_out_of_stock == true

      # At this point the user has come back from the Paypal form, and we get one
      # last chance to interact with the payment process before the money moves...
      last_payment = Orders::FindPaymentService.new(@order).last_pending_paypal_payment

      if last_payment.nil?
        flash[:error] = Spree.t('flash.no_payment_found', scope: 'paypal')
        return redirect_to main_app.checkout_step_path(:payment)
      end

      last_payment.update!(
        source: Spree::PaypalExpressCheckout.create(
          token: params[:token],
          payer_id: params[:PayerID]
        )
      )

      process_payment_completion!
    end

    def cancel
      flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
      redirect_to main_app.checkout_path
    end

    private

    def express_checkout_request_details(order)
      {
        SetExpressCheckoutRequestDetails: {
          InvoiceID: order.number,
          BuyerEmail: order.email,
          ReturnURL: payment_gateways_confirm_paypal_url(
            payment_method_id: params[:payment_method_id], utm_nooverride: 1
          ),
          CancelURL: payment_gateways_cancel_paypal_url,
          SolutionType: payment_method.preferred_solution.presence || "Mark",
          LandingPage: payment_method.preferred_landing_page.presence || "Billing",
          cppheaderimage: payment_method.preferred_logourl.presence || "",
          NoShipping: 1,
          PaymentDetails: [payment_details]
        }
      }
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def permit_parameters!
      params.permit(:token, :payment_method_id, :PayerID)
    end

    def reset_order_when_complete
      return unless current_order.complete?

      order_completion_reset(current_order)
    end

    def provider
      payment_method.provider
    end

    def payment_details
      Paypal::PaymentDetailsService.new(order: @order, address_required: address_required?).call
    end

    def address_required?
      payment_method.preferred_solution.eql?('Sole')
    end
  end
end
