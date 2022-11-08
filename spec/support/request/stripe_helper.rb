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

  def stripe_enable
    RSpec::Mocks.with_temporary_scope do
      allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true)
    end
  end

  def with_stripe_setup(api_key = "sk_test_12345", publishable_key = "pk_test_12345")
    original_keys = [Stripe.api_key, Stripe.publishable_key]

    Stripe.api_key = api_key
    Stripe.publishable_key = publishable_key

    yield

    Stripe.api_key, Stripe.publishable_key = original_keys
  end
end
