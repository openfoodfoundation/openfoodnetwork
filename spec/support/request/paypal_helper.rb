# frozen_string_literal: true

module PaypalHelper
  def stub_paypal_response(options)
    paypal_response = double(:response, success?: options[:success], errors: [])
    paypal_provider = double(
      :provider,
      build_set_express_checkout: nil,
      set_express_checkout: paypal_response
    )
    allow_any_instance_of(Spree::PaypalController).to receive(:provider).
      and_return(paypal_provider)
  end
end
