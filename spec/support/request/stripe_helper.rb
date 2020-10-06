# frozen_string_literal: true

module StripeHelper
  def checkout_with_stripe
    visit checkout_path
    checkout_as_guest

    fill_out_form(
      free_shipping.name,
      stripe_sca_payment_method.name,
      save_default_addresses: false
    )
    fill_out_card_details
    place_order
  end

  def fill_out_card_details
    expect(page).to have_css("input[name='cardnumber']")
    fill_in 'Card number', with: '4242424242424242'
    fill_in 'MM / YY', with: "01/#{DateTime.now.year + 1}"
    fill_in 'CVC', with: '123'
  end

  def fill_in_card_details_in_backoffice
    choose "StripeSCA"
    fill_in "cardholder_name", with: "David Gilmour"
    fill_in "stripe-cardnumber", with: "4242424242424242"
    fill_in "exp-date", with: "01-01-2050"
    fill_in "cvc", with: "678"
  end

  def setup_stripe
    allow(Stripe).to receive(:api_key) { "sk_test_12345" }
    allow(Stripe).to receive(:publishable_key) { "pk_test_12345" }
    Spree::Config.set(stripe_connect_enabled: true)
  end

  def stub_payment_intents_post_request(order:, response: {}, stripe_account_header: true)
    stub = stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(basic_auth: ["sk_test_12345", ""], body: /.*#{order.number}/)
    stub = stub.with(headers: { 'Stripe-Account' => 'abc123' }) if stripe_account_header
    stub.to_return(payment_intent_authorize_response_mock(response))
  end

  def stub_payment_intents_post_request_with_redirect(order:, redirect_url:)
    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(basic_auth: ["sk_test_12345", ""], body: /.*#{order.number}/)
      .to_return(payment_intent_redirect_response_mock(redirect_url))
  end

  def stub_payment_intent_get_request(response: {}, stripe_account_header: true)
    stub = stub_request(:get, "https://api.stripe.com/v1/payment_intents/pi_123")
    stub = stub.with(headers: { 'Stripe-Account' => 'abc123' }) if stripe_account_header
    stub.to_return(payment_intent_authorize_response_mock(response))
  end

  def stub_payment_methods_post_request(response: {})
    stub_request(:post, "https://api.stripe.com/v1/payment_methods")
      .with(body: { payment_method: "pm_123" },
            headers: { 'Stripe-Account' => 'abc123' })
      .to_return(hub_payment_method_response_mock(response))
  end

  def stub_successful_capture_request(order:, response: {})
    stub_capture_request(order, payment_successful_capture_mock(response))
  end

  def stub_failed_capture_request(order:, response: {})
    stub_capture_request(order, payment_failed_capture_mock(response))
  end

  def stub_capture_request(order, response_mock)
    stub_request(:post, "https://api.stripe.com/v1/payment_intents/pi_123/capture")
      .with(body: { amount_to_capture: Spree::Money.new(order.total).cents },
            headers: { 'Stripe-Account' => 'abc123' })
      .to_return(response_mock)
  end

  private

  def payment_intent_authorize_response_mock(options)
    { status: options[:code] || 200,
      body: JSON.generate(id: "pi_123",
                          object: "payment_intent",
                          amount: 2000,
                          amount_received: 2000,
                          status: options[:intent_status] || "requires_capture",
                          last_payment_error: nil,
                          charges: { data: [{ id: "ch_1234", amount: 2000 }] }) }
  end

  def payment_intent_redirect_response_mock(redirect_url)
    { status: 200, body: JSON.generate(id: "pi_123",
                                       object: "payment_intent",
                                       next_source_action: {
                                         type: "authorize_with_url",
                                         authorize_with_url: { url: redirect_url }
                                       },
                                       status: "requires_source_action") }
  end

  def payment_successful_capture_mock(options)
    { status: options[:code] || 200,
      body: JSON.generate(object: "payment_intent",
                          amount: 2000,
                          charges: { data: [{ id: "ch_1234", amount: 2000 }] }) }
  end

  def payment_failed_capture_mock(options)
    { status: options[:code] || 402,
      body: JSON.generate(error: { message:
                                     options[:message] || "payment-method-failure" }) }
  end

  def hub_payment_method_response_mock(options)
    { status: options[:code] || 200,
      body: JSON.generate(id: "pm_456", customer: "cus_A123") }
  end
end

