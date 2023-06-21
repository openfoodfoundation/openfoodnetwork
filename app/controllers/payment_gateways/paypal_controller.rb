# frozen_string_literal: true

module PaymentGateways
  class PaypalController < ::BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :destroy_orphaned_paypal_payments, only: :confirm
    before_action :load_checkout_order, only: [:express, :confirm]
    before_action :handle_insufficient_stock, only: [:express, :confirm]
    before_action :check_order_cycle_expiry, only: [:express, :confirm]
    before_action :permit_parameters!

    after_action :reset_order_when_complete, only: :confirm

    def express
      pp_request = provider.build_set_express_checkout(
        express_checkout_request_details(@order)
      )

      begin
        pp_response = provider.set_express_checkout(pp_request)
        if pp_response.success?
          # At this point Paypal has *provisionally* accepted that the payment can now be placed,
          # and the user will be redirected to a Paypal payment page. On completion, the user is
          # sent back and the response is handled in the #confirm action in this controller.
          redirect_to provider.express_checkout_url(pp_response, useraction: 'commit')
        else
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
      # At this point the user has come back from the Paypal form, and we get one
      # last chance to interact with the payment process before the money moves...

      @order.payments.create!(
        source: Spree::PaypalExpressCheckout.create(
          token: params[:token],
          payer_id: params[:PayerID]
        ),
        amount: @order.total,
        payment_method: payment_method
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
          PaymentDetails: [payment_details(order)]
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

    # See #1074 and #1837 for more detail on why we need this
    # An 'orphaned' Spree::Payment is created for every call to CheckoutController#update
    # for orders that are processed using a Spree::Gateway::PayPalExpress payment method
    # These payments are 'orphaned' because they are never used by the spree_paypal_express gem
    # which creates a brand new Spree::Payment from scratch in PayPalController#confirm
    # However, the 'orphaned' payments are useful when applying a transaction fee, because the fees
    # need to be calculated before the order details are sent to PayPal for confirmation
    # This is our best hook for removing the orphaned payments at an appropriate time. ie. after
    # the payment details have been confirmed, but before any payments have been processed
    def destroy_orphaned_paypal_payments
      return unless payment_method.is_a?(Spree::Gateway::PayPalExpress)

      orphaned_payments = current_order.payments.
        where(payment_method_id: payment_method.id, source_id: nil)
      orphaned_payments.each(&:destroy)
    end

    def provider
      payment_method.provider
    end

    def payment_details(order)
      items = PaypalItemsBuilder.new(order).call

      item_sum = items.sum { |i| i[:Quantity] * i[:Amount][:value] }
      tax_adjustments_total = current_order.all_adjustments.tax.additional.sum(:amount)

      if item_sum.zero?
        # Paypal does not support no items or a zero dollar ItemTotal
        # This results in the order summary being simply "Current purchase"
        {
          OrderTotal: {
            currencyID: current_order.currency,
            value: current_order.total
          }
        }
      else
        {
          OrderTotal: {
            currencyID: current_order.currency,
            value: current_order.total
          },
          ItemTotal: {
            currencyID: current_order.currency,
            value: item_sum
          },
          ShippingTotal: {
            currencyID: current_order.currency,
            value: current_order.ship_total
          },
          TaxTotal: {
            currencyID: current_order.currency,
            value: tax_adjustments_total,
          },
          ShipToAddress: address_options,
          PaymentDetailsItem: items,
          ShippingMethod: "Shipping Method Name Goes Here",
          PaymentAction: "Sale"
        }
      end
    end

    def address_options
      return {} unless address_required?

      {
        Name: current_order.bill_address.try(:full_name),
        Street1: current_order.bill_address.address1,
        Street2: current_order.bill_address.address2,
        CityName: current_order.bill_address.city,
        Phone: current_order.bill_address.phone,
        StateOrProvince: current_order.bill_address.state_text,
        Country: current_order.bill_address.country.iso,
        PostalCode: current_order.bill_address.zipcode
      }
    end

    def address_required?
      payment_method.preferred_solution.eql?('Sole')
    end
  end
end
