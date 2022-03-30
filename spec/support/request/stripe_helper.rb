# frozen_string_literal: true

module StripeHelper
  def checkout_with_stripe(guest_checkout: true, remember_card: false)
    visit checkout_path
    checkout_as_guest if guest_checkout
    fill_out_form(
      free_shipping.name,
      stripe_sca_payment_method.name,
      save_default_addresses: false
    )
    fill_out_card_details
    check "Remember this card?" if remember_card
    place_order
  end

  def fill_out_card_details
    fill_in "stripe-cardnumber", with: '4242424242424242'
    fill_in "exp-date", with: "01/#{DateTime.now.year + 1}"
    fill_in "cvc", with: "123"
  end

  def fill_in_card_details_in_backoffice
    choose "StripeSCA"
    fill_in "cardholder_name", with: "David Gilmour"
    fill_in "stripe-cardnumber", with: "4242424242424242"
    fill_in "exp-date", with: "01-01-2050"
    fill_in "cvc", with: "678"
  end

  def setup_stripe
    Stripe.api_key = "sk_test_12345"
    Stripe.publishable_key = "pk_test_12345"
    Spree::Config.set(stripe_connect_enabled: true)
  end

  # from puffing-billy setup
  def stub_stripe_token_request!(success: true)
    if success
      stub_success_token
    else
      stub_failed_token
    end
  end

  private

  def stub_success_token
    proxy.stub('https://api.stripe.com:443/v1/tokens').
      and_return(Proc.new { |params|
      { :code => 200, :text => "#{params['callback'][0]}({
        'id': 'tok_2Z0Jh5UWnSrAeL',
        'livemode': false,
        'created': 1379062337,
        'used': false,
        'object': 'token',
        'type': 'card'
      },
      200)" } })
  end

  def stub_failed_token
    proxy.stub('https://api.stripe.com:443/v1/tokens').
      and_return(Proc.new { |params|
      { :code => 200, :text => "#{params['callback'][0]}({
        'error': {
          'message': 'Your card number is incorrect.',
          'type': 'card_error',
          'param': 'number',
          'code': 'incorrect_number'
        }
      }
      , 402)" } })
  end

  #def stub_stripe!
  #  allow(controller).to receive(:current_order).and_return(order)
  #  stub_successful_capture_request(order: order)
  #  allow(controller).to receive(:spree_current_user).and_return(user)
  #end
end



