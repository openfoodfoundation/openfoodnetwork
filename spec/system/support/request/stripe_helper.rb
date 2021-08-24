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
    Stripe.api_key = "sk_test_12345"
    Stripe.publishable_key = "pk_test_12345"
    Spree::Config.set(stripe_connect_enabled: true)
  end
end
