# frozen_string_literal: true

module PaypalHelper
  # Initial request to confirm the payment can be placed (before redirecting to paypal)
  def stub_paypal_response(options)
    paypal_response = double(:response, success?: options[:success], errors: [])
    paypal_provider = double(
      :provider,
      build_set_express_checkout: nil,
      set_express_checkout: paypal_response,
      express_checkout_url: options[:redirect]
    )
    allow_any_instance_of(PaymentGateways::PaypalController).to receive(:provider).
      and_return(paypal_provider)
  end

  # Additional request to re-confirm the payment, when the order is finalised.
  def stub_paypal_confirm
    stub_request(:post, "https://api-3t.sandbox.paypal.com/2.0/")
      .to_return(status: 200, body: mocked_xml_response )
  end

  private

  def mocked_xml_response
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <Envelope><Body>
      <GetExpressCheckoutDetailsResponse>
        <Ack>Success</Ack>
        <PaymentDetails>Something</PaymentDetails>
        <DoExpressCheckoutPaymentResponseDetails>
          <PaymentInfo><TransactionID>s0metran$act10n</TransactionID></PaymentInfo>
        </DoExpressCheckoutPaymentResponseDetails>
      </GetExpressCheckoutDetailsResponse>
    </Body></Envelope>"
  end
end
