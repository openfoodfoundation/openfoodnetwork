# frozen_string_literal: true

Spree::PaypalController.class_eval do
  before_action :enable_embedded_shopfront
  before_action :destroy_orphaned_paypal_payments, only: :confirm
  after_action :reset_order_when_complete, only: :confirm
  before_action :permit_parameters!

  def express
    order = current_order || raise(ActiveRecord::RecordNotFound)
    items = order.line_items.map(&method(:line_item))

    tax_adjustments = order.adjustments.tax
    # TODO: Remove in Spree 2.2
    tax_adjustments = tax_adjustments.additional if tax_adjustments.respond_to?(:additional)
    shipping_adjustments = order.adjustments.shipping

    order.adjustments.eligible.each do |adjustment|
      next if (tax_adjustments + shipping_adjustments).include?(adjustment)

      items << {
        Name: adjustment.label,
        Quantity: 1,
        Amount: {
          currencyID: order.currency,
          value: adjustment.amount
        }
      }
    end

    # Because PayPal doesn't accept $0 items at all.
    # See #10
    # https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECCustomizing
    # "It can be a positive or negative value but not zero."
    items.reject! do |item|
      item[:Amount][:value].zero?
    end
    pp_request = provider.build_set_express_checkout(express_checkout_request_details(order, items))

    begin
      pp_response = provider.set_express_checkout(pp_request)
      if pp_response.success?
        redirect_to provider.express_checkout_url(pp_response, useraction: 'commit')
      else
        flash[:error] = Spree.t('flash.generic_error', scope: 'paypal', reasons: pp_response.errors.map(&:long_message).join(" "))
        redirect_to spree.checkout_state_path(:payment)
      end
    rescue SocketError
      flash[:error] = Spree.t('flash.connection_failed', scope: 'paypal')
      redirect_to spree.checkout_state_path(:payment)
    end
  end

  def cancel
    flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
    redirect_to main_app.checkout_path
  end

  # Clears the cached order. Required for #current_order to return a new order
  # to serve as cart. See https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/order.rb#L14
  # for details.
  def expire_current_order
    session[:order_id] = nil
    @current_order = nil
  end

  private

  def permit_parameters!
    params.permit(:token, :payment_method_id, :PayerID)
  end

  def reset_order_when_complete
    if current_order.complete?
      flash[:notice] = t(:order_processed_successfully)

      OrderCompletionReset.new(self, current_order).call
      session[:access_token] = current_order.token
    end
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

    orphaned_payments = current_order.payments.where(payment_method_id: payment_method.id, source_id: nil)
    orphaned_payments.each(&:destroy)
  end

  def completion_route(order)
    spree.order_path(order, token: order.token)
  end

  def express_checkout_request_details(order, items)
    {
      SetExpressCheckoutRequestDetails: {
        InvoiceID: order.number,
        BuyerEmail: order.email,
        ReturnURL: spree.confirm_paypal_url(payment_method_id: params[:payment_method_id], utm_nooverride: 1),
        CancelURL: spree.cancel_paypal_url,
        SolutionType: payment_method.preferred_solution.presence || "Mark",
        LandingPage: payment_method.preferred_landing_page.presence || "Billing",
        cppheaderimage: payment_method.preferred_logourl.presence || "",
        NoShipping: 1,
        PaymentDetails: [payment_details(items)]
      }
    }
  end
end
